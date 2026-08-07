#!/usr/bin/env python3
"""Validate `metadata/app-store.json` against Apple's field limits and ours.

App Store Connect silently punishes metadata mistakes: a keyword field one
character over 100 is not truncated, it is **ignored in full**, and a word
repeated between the name and the keyword field spends budget on a token
Apple already indexed. Neither shows up as an error anywhere — you just rank
for less. This catches both before they ship.

It also enforces the repo's own accuracy rule: no metadata field may name a
feature the binary doesn't have (Guideline 2.3.1). That rule already cost this
project a rewrite of the name, the subtitle and the keywords once.

    python3 scripts/aso_lint.py              # validate, non-zero exit on failure
    python3 scripts/aso_lint.py --print      # paste-ready blocks for ASC
    python3 scripts/aso_lint.py --fastlane   # write fastlane/metadata for `deliver`
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "metadata" / "app-store.json"

# Apple's published limits, in characters.
LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "whats_new": 4000,
    "iap_display_name": 30,
    "iap_description": 45,
    "review_notes": 4000,
}

# Words too generic to be worth a keyword slot, or that Apple ignores.
STOPWORDS = {
    "a", "an", "and", "app", "apps", "best", "by", "for", "free", "in",
    "iphone", "ios", "new", "of", "the", "to", "with", "your",
}


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.warnings: list[str] = []
        self.lines: list[str] = []

    def ok(self, label: str, detail: str = "") -> None:
        self.lines.append(f"  PASS  {label}{f' — {detail}' if detail else ''}")

    def fail(self, label: str, detail: str) -> None:
        self.failures.append(f"{label}: {detail}")
        self.lines.append(f"  FAIL  {label} — {detail}")

    def warn(self, label: str, detail: str) -> None:
        self.warnings.append(f"{label}: {detail}")
        self.lines.append(f"  WARN  {label} — {detail}")


def tokens(text: str) -> set[str]:
    """Index tokens Apple would extract: lowercased words, stems folded.

    Apple stems plurals, so `chart` and `charts` occupy the same slot — which
    is exactly the duplication we're hunting for.
    """
    words = re.findall(r"[a-z0-9]+", text.lower())
    return {stem(word) for word in words if word not in STOPWORDS}


def stem(word: str) -> str:
    if len(word) > 4 and word.endswith("ies"):
        return word[:-3] + "y"
    if len(word) > 3 and word.endswith("es") and not word.endswith("ses"):
        return word[:-2]
    if len(word) > 3 and word.endswith("s"):
        return word[:-1]
    return word


def check_length(report: Report, label: str, value: str, limit_key: str) -> None:
    limit = LIMITS[limit_key]
    length = len(value)
    if length > limit:
        report.fail(label, f"{length}/{limit} chars — {length - limit} over")
    elif limit_key == "keywords" and length < limit * 0.9:
        report.warn(label, f"{length}/{limit} chars — {limit - length} unused")
    else:
        report.ok(label, f"{length}/{limit} chars")


def check_keyword_field(report: Report, label: str, value: str) -> list[str]:
    check_length(report, label, value, "keywords")

    if " " in value:
        report.fail(label, "contains a space — every space is a wasted keyword character")
    if value.endswith(",") or ",," in value:
        report.fail(label, "empty keyword slot (stray comma)")

    words = [w for w in value.split(",") if w]
    duplicates = {w for w in words if words.count(w) > 1}
    if duplicates:
        report.fail(label, f"repeated inside the field: {', '.join(sorted(duplicates))}")

    stems: dict[str, str] = {}
    for word in words:
        key = stem(word.lower())
        if key in stems and stems[key] != word:
            report.warn(label, f"'{word}' and '{stems[key]}' stem alike — Apple indexes them once")
        stems[key] = word

    for word in words:
        if word.lower() in STOPWORDS:
            report.warn(label, f"'{word}' is a stopword and buys nothing")
    return words


# Cues that a sentence is *denying* a capability rather than claiming it.
NEGATION_CUES = ("not ", "n't", "never", "no ", "isn't", "yet", "before")


def check_accuracy(report: Report, label: str, value: str, forbidden: list[str],
                   narrative: bool = False) -> None:
    """Fail when a field names a feature the binary doesn't have.

    Indexed and promotional fields may not name one at all — a keyword is a
    claim, and Apple reads it as one. The description and release notes are
    the exception: saying "Lumina doesn't read palms today" is the honest
    move, and the app's whole positioning rests on being able to say it. So
    for those two, each sentence naming the feature has to be denying it.
    """
    lowered = value.lower()
    hits = [term for term in forbidden if term in lowered]
    if not hits:
        return

    if not narrative:
        report.fail(label, f"names an unshipped feature: {', '.join(hits)}")
        return

    for sentence in re.split(r"(?<=[.!?])\s+|\n+", lowered):
        named = [term for term in forbidden if term in sentence]
        if named and not any(cue in sentence for cue in NEGATION_CUES):
            report.fail(
                label,
                f"claims {', '.join(named)} without denying it: \"{sentence.strip()[:70]}\"",
            )
            return
    report.ok(label, f"mentions {', '.join(hits)}, and denies it — allowed")


SITE_ROOT = ROOT / "docs"
SITE_PREFIX = "https://wrexist.github.io/Lumina/"


def check_urls(report: Report, urls: dict) -> None:
    """Every URL we host must exist in `docs/` before submission.

    A Support or Privacy Policy URL that 404s is an automatic rejection, and
    the failure is invisible from App Store Connect — it accepts any string.
    This can't test liveness offline, but it catches the real-world version:
    a metadata URL pointing at a page nobody ever wrote. (`web-tests/` covers
    liveness once Pages is up.)
    """
    for field, url in urls.items():
        if field.startswith("$") or not isinstance(url, str):
            continue
        if not url.startswith(SITE_PREFIX):
            continue
        page = url[len(SITE_PREFIX):] or "index.html"
        if (SITE_ROOT / page).exists():
            report.ok(f"url {field}", f"docs/{page} exists")
        else:
            report.fail(f"url {field}", f"docs/{page} does not exist — this URL would 404")


PROJECT_YML = ROOT / "project.yml"


def check_version(report: Report, version: str, whats_new: str) -> None:
    """The binary's marketing version has to match the version this metadata
    describes.

    App Store Connect attaches an uploaded build to the App Store version whose
    number matches its `CFBundleShortVersionString`. Upload a build stamped
    0.1.0 against a 1.0 release and it does not appear in the build list — no
    error, no email, just an empty list and no clue why. This repo shipped
    exactly that state: `project.yml` said 0.1.0 while the release notes below
    opened with "Lumina 1.0."
    """
    if not PROJECT_YML.exists():
        report.fail("version", "project.yml is missing — the binary's version can't be checked")
        return
    found = re.search(
        r'^\s*MARKETING_VERSION:\s*"?([0-9.]+)"?\s*$',
        PROJECT_YML.read_text(encoding="utf-8"),
        re.M,
    )
    if not found:
        report.fail("version", "no MARKETING_VERSION in project.yml")
        return

    marketing = found.group(1)
    if marketing != version:
        report.fail(
            "version",
            f"project.yml stamps {marketing}, this metadata describes {version} — "
            "a build at the wrong version can't be attached to the release",
        )
        return
    report.ok("version", f"{version} in both project.yml and metadata")

    # Release notes that open by naming a version have to name this one.
    named = re.search(r"\b(\d+\.\d+(?:\.\d+)?)\b", whats_new.split("\n", 1)[0])
    if named and named.group(1) != version:
        report.fail("whats_new", f"opens with {named.group(1)} but the release is {version}")
    elif named:
        report.ok("whats_new version", f"names {version}, matching the release")


def check_contact(report: Report, contact: dict) -> None:
    """The support contact has to be a mailbox that exists, and the published
    support page has to show the same one.

    `lumina.app` was in every published address for months and was never
    registered — mail to it bounced, which is a rejection on its own and a
    dead end for anyone who needed help.
    """
    email = contact.get("support_email", "")
    if "@" not in email:
        report.fail("support email", "not an address")
        return

    domain = email.rsplit("@", 1)[1].lower()
    if domain in {d.lower() for d in contact.get("unregistered_domains", [])}:
        report.fail("support email", f"{domain} is not registered — mail to it bounces")
        return
    report.ok("support email", email)

    support_page = SITE_ROOT / "support.html"
    if support_page.exists():
        published = support_page.read_text(encoding="utf-8")
        if email.lower() in published.lower():
            report.ok("support page", "publishes the same address")
        else:
            report.fail("support page", f"docs/support.html does not show {email}")

    for page in sorted(SITE_ROOT.glob("*.html")):
        text = page.read_text(encoding="utf-8").lower()
        for dead in contact.get("unregistered_domains", []):
            if f"@{dead.lower()}" in text:
                report.fail(f"docs/{page.name}", f"still links mail at {dead}")


def check_bench(report: Report, bench: dict | None, live: list[str],
                indexed: set[str], forbidden: list[str]) -> None:
    """Keep the swap candidates usable.

    A bench term that is already live, or that names an unshipped feature, is
    a swap that would waste a release — and keyword fields can only change
    with a new version, so a wasted swap costs months.
    """
    if not bench:
        return

    live_stems = {stem(word.lower()) for word in live} | indexed
    candidates = bench.get("candidates", [])
    for candidate in candidates:
        term = candidate["term"]
        if stem(term.lower()) in live_stems:
            report.fail("keyword bench", f"'{term}' is already live — nothing to swap in")
        if any(bad in term.lower() for bad in forbidden):
            report.fail("keyword bench", f"'{term}' names an unshipped feature")

        replaces = candidate.get("replaces")
        if replaces and replaces not in live:
            report.fail("keyword bench",
                        f"'{term}' says it replaces '{replaces}', which isn't in any live field")

    for entry in bench.get("do_not_use", []):
        if stem(entry["term"].lower()) in live_stems:
            report.fail("keyword bench", f"'{entry['term']}' is on the do-not-use list but is live")

    report.ok("keyword bench", f"{len(candidates)} candidates, none live, each with a swap target")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--print", dest="emit", action="store_true",
                        help="print paste-ready App Store Connect blocks")
    parser.add_argument("--fastlane", action="store_true",
                        help="write the fastlane/metadata tree `deliver` uploads")
    args = parser.parse_args()

    data = json.loads(METADATA.read_text(encoding="utf-8"))
    locales = data["localizations"]
    forbidden = data["accuracy_rules"]["forbidden_terms"]
    primary = locales["en-US"]

    if args.emit:
        emit(data)
        return 0

    if args.fastlane:
        write_fastlane(data)
        return 0

    report = Report()
    report.lines.append("App Store metadata — en-US")

    check_length(report, "name", primary["name"], "name")
    check_length(report, "subtitle", primary["subtitle"], "subtitle")
    check_length(report, "promotional_text", primary["promotional_text"], "promotional_text")
    check_length(report, "description", primary["description"], "description")
    check_length(report, "whats_new", primary["whats_new"], "whats_new")
    check_length(report, "review notes", data["review"]["notes"], "review_notes")
    check_version(report, data["version"], primary["whats_new"])

    # The three indexed fields must not spend budget on the same token twice.
    name_tokens = tokens(primary["name"])
    subtitle_tokens = tokens(primary["subtitle"])
    overlap = name_tokens & subtitle_tokens
    if overlap:
        report.fail("name/subtitle", f"both index {', '.join(sorted(overlap))}")
    else:
        report.ok("name/subtitle", "no shared tokens")

    indexed = name_tokens | subtitle_tokens
    all_keywords: list[str] = []
    for locale, payload in locales.items():
        if "keywords" not in payload:
            continue
        words = check_keyword_field(report, f"{locale} keywords", payload["keywords"])
        repeated = {w for w in words if stem(w.lower()) in indexed}
        if repeated:
            report.fail(
                f"{locale} keywords",
                f"already indexed by the name or subtitle: {', '.join(sorted(repeated))}",
            )
        cross = {w for w in words if stem(w.lower()) in {stem(k.lower()) for k in all_keywords}}
        if cross:
            report.fail(f"{locale} keywords", f"duplicates another locale: {', '.join(sorted(cross))}")
        all_keywords.extend(words)

    narrative_fields = {"description", "whats_new"}
    for locale, payload in locales.items():
        for field in ("name", "subtitle", "keywords", "promotional_text", "description", "whats_new"):
            if field in payload:
                check_accuracy(report, f"{locale} {field}", payload[field], forbidden,
                               narrative=field in narrative_fields)

    for iap in data["in_app_purchases"]:
        check_length(report, f"IAP '{iap['reference_name']}' display name",
                     iap["display_name"], "iap_display_name")
        check_length(report, f"IAP '{iap['reference_name']}' description",
                     iap["description"], "iap_description")
        check_accuracy(report, f"IAP '{iap['reference_name']}'",
                       iap["display_name"] + " " + iap["description"], forbidden)

    check_urls(report, data["urls"])
    check_contact(report, data["contact"])
    check_bench(report, data.get("keyword_bench"), all_keywords, indexed, forbidden)

    total_indexed = len(primary["name"]) + len(primary["subtitle"]) + sum(
        len(p["keywords"]) for p in locales.values() if "keywords" in p
    )
    report.lines.append(f"\n  {total_indexed} indexed characters across "
                        f"{sum(1 for p in locales.values() if 'keywords' in p)} keyword fields, "
                        f"{len(set(all_keywords))} distinct keywords")

    print("\n".join(report.lines))
    if report.failures:
        print(f"\n{len(report.failures)} failure(s)")
        return 1
    print(f"\nAll checks passed ({len(report.warnings)} warning(s))")
    return 0


FASTLANE = ROOT / "fastlane" / "metadata"

# Which JSON field lands in which file `fastlane deliver` expects.
FASTLANE_FILES = {
    "name": "name.txt",
    "subtitle": "subtitle.txt",
    "keywords": "keywords.txt",
    "promotional_text": "promotional_text.txt",
    "description": "description.txt",
    "whats_new": "release_notes.txt",
}


def write_fastlane(data: dict) -> None:
    """Emit the `fastlane/metadata/` tree `deliver` reads.

    Fifteen paste operations into App Store Connect is fifteen chances to
    paste the wrong field, and no way to diff what was actually uploaded.
    `fastlane deliver` reads this tree instead — same source of truth as the
    linter, so the store page and the repo cannot disagree.
    """
    for locale, payload in data["localizations"].items():
        directory = FASTLANE / locale
        directory.mkdir(parents=True, exist_ok=True)
        for field, filename in FASTLANE_FILES.items():
            if field in payload:
                (directory / filename).write_text(payload[field] + "\n", encoding="utf-8")

    urls = data["urls"]
    root_files = {
        "primary_category.txt": data["primary_category"],
        "secondary_category.txt": data["secondary_category"],
        "copyright.txt": urls["copyright"],
    }
    for filename, value in root_files.items():
        (FASTLANE / filename).write_text(value + "\n", encoding="utf-8")

    en = FASTLANE / "en-US"
    en.mkdir(parents=True, exist_ok=True)
    for filename, value in {
        "marketing_url.txt": urls["marketing"],
        "support_url.txt": urls["support"],
        "privacy_url.txt": urls["privacy_policy"],
    }.items():
        (en / filename).write_text(value + "\n", encoding="utf-8")

    review = FASTLANE / "review_information"
    review.mkdir(parents=True, exist_ok=True)
    (review / "notes.txt").write_text(data["review"]["notes"] + "\n", encoding="utf-8")
    (review / "email_address.txt").write_text(
        data["contact"]["support_email"] + "\n", encoding="utf-8")

    count = sum(1 for _ in FASTLANE.rglob("*.txt"))
    print(f"wrote {count} files under {FASTLANE.relative_to(ROOT)}/")


def emit(data: dict) -> None:
    primary = data["localizations"]["en-US"]
    blocks = [
        ("App Name (30)", primary["name"]),
        ("Subtitle (30)", primary["subtitle"]),
        ("Keywords en-US (100)", primary["keywords"]),
        ("Keywords es-MX (100)", data["localizations"]["es-MX"]["keywords"]),
        ("Keywords en-GB (100)", data["localizations"]["en-GB"]["keywords"]),
        ("Promotional Text (170)", primary["promotional_text"]),
        ("Description (4000)", primary["description"]),
        ("What's New (4000)", primary["whats_new"]),
        ("App Review Notes", data["review"]["notes"]),
    ]
    for label, value in blocks:
        print(f"\n=== {label} — {len(value)} chars ===\n{value}")


if __name__ == "__main__":
    sys.exit(main())
