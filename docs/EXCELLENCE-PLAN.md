# Lumina — Excellence Plan ("best in the niche")

The comprehensive, prioritized list to make Lumina unambiguously the best app
in the astrology + palm category. Organised by impact and by whether I can
build it **autonomously** (no provisioning) or it's **blocked** on a key/account
only the owner can supply. Checkboxes track live progress; I work top-down
through the unblocked items, each as its own CI-verified commit.

Legend: ✅ done · 🔨 building · ⏳ queued · 🔒 blocked (needs provisioning)

---

## 0. Already shipped this session (real, CI-green)

- ✅ Real transits → **daily reading** + "what's happening" (Today)
- ✅ De-clustered chart wheel · monochrome-gold glyphs (no emoji)
- ✅ Grounded interpretations: **planets, signs, houses, aspects**
- ✅ **Ask your chart** (deterministic Q&A)
- ✅ Real **synastry**: aspects + weighted score + relationship summary
- ✅ **"Why these?"** transparency sheet · browsable **Glossary**
- ✅ Premium/clarity/a11y: jargon purge, Dynamic Type, VoiceOver
- ✅ Competitive analysis · audits · no-Mac screenshot pipeline (all 5 tabs)

---

## 1. Premium polish (unblocked — building now)

- 🔨 **Soft-delete + Undo** for friends & journal entries (swipe → undo snackbar; modern, recoverable, beats a blunt confirm dialog). New `LuminaSnackbar`.
- ✅ **Big-3 tappable readings** — tap Sun/Moon → placement reading, Rising → ascendant reading (new `AscendantInterpreter` + `AscendantDetailSheet`).
- ✅ **Transit-tied Reflect prompt** — the day's strongest transit shapes the journal prompt (`TransitPrompt`), so Today and Reflect cohere; falls back to the date pool offline.
- ⏳ **Empty-state pass** — every list/section gets a premium, never-dead-end empty state.
- ⏳ **Motion & haptics polish** — `.smooth` cross-fades, light haptics on key taps, respect Reduce Motion.
- ⏳ **App icon** — replace the placeholder orb with a refined mark.

## 2. New grounded features (unblocked, deterministic — no LLM/keys)

- ✅ **"What's coming"** — upcoming **exact** transit dates (root-find when each transiting aspect perfects). The category's "timing" promise, done for real. Backend `/forecast` + Today "What's coming" card.
- ✅ **Moon phase** — today's lunar phase, illumination, next new/full. Backend `/moon` + Today "Tonight's Moon" card. (Void-of-course deferred.)
- ✅ **Composite chart** (relationship midpoints) — deepens People beyond synastry. Backend `/composite` + Friend "relationship as one chart" card.
- ✅ **Secondary progressions** — your evolving chart (day-for-a-year). Backend `/progressions` + Today "Your current chapter" card (progressed Moon/Sun via `ProgressedChapter`).
- 🔨 **Returns & retrogrades** — **retrogrades done**: backend `/retrogrades` (current state + next station via velocity root-finding) + Today "Retrogrades" card. Saturn/Jupiter return dates still to come.
- ✅ **Local transit notifications** — opt-in, on-device (`UNUserNotificationCenter`, no OneSignal), capped at 5, delivered 9am on the transit's day (never the exact minute), never doom. `TransitNotificationPlanner` + `TransitNotificationScheduler` + Settings toggle.
- ✅ **Share your chart as an image** — `ChartShareCard` rendered via `ImageRenderer` to a PNG, shared through a `ShareLink` from the Chart toolbar (`ChartShareButton`).

## 3. Differentiators ("better than anyone")

- 🔨 **Palm — real, no fakery.** Phase A engine **done** (unblocked): `PalmReader` + `PalmFeatureExtractor` derive the four classical hand types from real geometry (palm proportions + finger length), with a compile-checked `VNDetectHumanHandPoseRequest` adapter — all unit-tested. Remaining: the live capture UI (camera + overlay) needs on-device testing. Phase B (🔒): the line-segmentation U-Net for the four major lines.
- ✅ **Transparency everywhere** — show the real data behind every claim (started; extend to synastry & interpretations).
- ✅ **Honest, kind notifications** (see §2) — the explicit anti-Co-Star stance, shipped.

## 4. Quality & infra (unblocked)

- 🔨 Gitleaks secret-scan CI gate **done** (`secrets` job + `.gitleaks.toml`); coverage gate pending.
- ⏳ Expand snapshot coverage; refactor the screenshot harness so it scales.
- ⏳ More edge-case tests across the new deterministic engines.

## 5. Blocked — needs one-time provisioning by the owner

- 🔒 **Anthropic key** → free-text conversational "ask your chart" + RAG-grounded daily reading (the grounding layer is already built and waiting).
- 🔒 **Core ML palm model** → palm line-segmentation tracing (Phase B above).
- 🔒 **ElevenLabs** → voice narration of the daily reading.
- 🔒 **Supabase** → RAG corpus store + account sync/discovery.
- 🔒 **Apple Developer signing** → TestFlight builds on a real device.

---

### Working order (this push onward)
1. Soft-delete + Undo → 2. ✅ "What's coming" transits → 3. ✅ Composite chart →
4. ✅ Moon phase → 5. ✅ Big-3 taps → 6. ✅ Transit-tied Reflect prompt →
7. ✅ Local notifications → 8. ✅ Chart image share → 9. 🔨 Palm Phase A (engine done) →
10. empty-state/motion/icon polish → 11. infra gates.

I update this file as each lands.
