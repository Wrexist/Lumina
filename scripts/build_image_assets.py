#!/usr/bin/env python3
"""Derive the app's image assets from the masters in `assets/`.

`assets/*.png` holds the full-size generated art (1024² planets and
constellations, 1536×1024 illustrations, a 2:1 lunar texture) exactly as it
came out of the generator — those are the masters, never edited by hand and
never loaded by the app. This script resizes them into
`Lumina/Resources/Assets.xcassets/`, one `.imageset` per asset, and writes the
`Contents.json` Xcode needs.

Run it after replacing or adding a master:

    pip install Pillow
    python3 scripts/build_image_assets.py

Two deliberate choices:

* **@2x and @3x only.** The deployment target is iOS 26, so every device that
  can install Lumina has a Retina screen — a @1x slot would be dead weight in
  the binary.
* **Palette encoding for the line art, full RGBA for the spheres.** The
  constellations and illustrations are flat gold-on-transparent line work and
  quantise to a 256-colour palette with no visible change at ~1/5 the size.
  The planets carry soft alpha glows (the Sun's corona especially) that band
  badly under palette alpha, so they stay 8-bit RGBA.
"""

from __future__ import annotations

import json
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover - operator-facing message
    sys.exit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parent.parent
MASTERS = ROOT / "assets"
CATALOG = ROOT / "Lumina" / "Resources" / "Assets.xcassets"

PLANETS = [
    "planet-sun",
    "planet-mercury",
    "planet-venus",
    "planet-earth",
    "planet-mars",
    "planet-jupiter",
    "planet-saturn",
    "planet-uranus",
    "planet-neptune",
    "planet-pluto",
]

CONSTELLATIONS = [
    "constellation-aries",
    "constellation-taurus",
    "constellation-gemini",
    "constellation-cancer",
    "constellation-leo",
    "constellation-virgo",
    "constellation-libra",
    "constellation-scorpio",
    "constellation-sagittarius",
    "constellation-capricorn",
    "constellation-aquarius",
    "constellation-pisces",
]

ILLUSTRATIONS = ["empty-birth-info", "empty-people", "reveal-signature"]

TEXTURE = "moon-surface"


@dataclass(frozen=True)
class Group:
    """One folder of imagesets inside the catalog."""

    folder: str
    names: list[str]
    # Width in points; @2x and @3x are derived from it.
    point_width: int
    palette: bool
    # How to re-frame the art before scaling. See `reframe`.
    fit: str


GROUPS = [
    Group("Planets", PLANETS, point_width=128, palette=False, fit="none"),
    Group("Constellations", CONSTELLATIONS, point_width=64, palette=True, fit="square"),
    Group("Illustrations", ILLUSTRATIONS, point_width=256, palette=True, fit="trim"),
]

# Alpha below this counts as empty when measuring an asset's content box —
# high enough to ignore the faintest edge of a glow, low enough to keep a
# constellation's dimmest star.
ALPHA_FLOOR = 8

# Fraction of the square a constellation's longest side is scaled to occupy.
CONSTELLATION_FILL = 0.78

# Breathing room left around a trimmed illustration, as a fraction of its
# content box.
ILLUSTRATION_PAD = 0.04

# The lunar texture is not a UI image: it is wrapped onto the SceneKit sphere
# in `MoonSphere3DView`, so it ships at one fixed pixel size rather than in
# point-scaled slots. 1024×512 keeps the seam and the maria while staying
# under a megabyte; the master is only 1774px wide, so going larger would
# invent detail that isn't there.
TEXTURE_SIZE = (1024, 512)

CATALOG_INFO = {"author": "xcode", "version": 1}


def write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def encode(image: Image.Image, palette: bool) -> Image.Image:
    """Palette-quantise flat art; leave anything with a soft glow alone."""
    if not palette:
        return image
    return image.quantize(colors=256, method=Image.Quantize.FASTOCTREE)


def content_box(image: Image.Image) -> tuple[int, int, int, int]:
    """The art's real bounds, ignoring the transparent frame around it."""
    mask = image.getchannel("A").point(lambda value: 255 if value > ALPHA_FLOOR else 0)
    return mask.getbbox() or (0, 0, image.width, image.height)


def reframe(image: Image.Image, fit: str) -> Image.Image:
    """Re-compose a master so a whole set reads at one visual scale.

    The planets came out of the generator as a matched set — every sphere
    lands at ~71% of its frame, dead centre, with the Sun's corona and
    Saturn's rings the two deliberate exceptions. Touching those would undo
    the thing that makes them look like a set, so `fit="none"` leaves them
    exactly as generated.

    The constellations did not: the real star patterns range from Cancer's
    tight 30% to Virgo's sprawling 75%, so dropping the masters straight into
    a 36pt avatar would render some at a third the size of others. `"square"`
    trims each to its stars and re-pads it centred, which is what makes a
    People list look like one set of avatars instead of twelve crops.

    `"trim"` just removes the transparent margin (keeping a little padding)
    so the SwiftUI layout, not baked-in whitespace, decides how big an
    illustration sits in its slot.
    """
    if fit == "none":
        return image

    box = content_box(image)
    art = image.crop(box)

    if fit == "trim":
        pad_x = round(art.width * ILLUSTRATION_PAD)
        pad_y = round(art.height * ILLUSTRATION_PAD)
        canvas = Image.new("RGBA", (art.width + pad_x * 2, art.height + pad_y * 2), (0, 0, 0, 0))
        canvas.alpha_composite(art, (pad_x, pad_y))
        return canvas

    if fit == "square":
        side = round(max(art.width, art.height) / CONSTELLATION_FILL)
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        canvas.alpha_composite(art, ((side - art.width) // 2, (side - art.height) // 2))
        return canvas

    raise ValueError(f"unknown fit: {fit}")


def build_imageset(group: Group, name: str) -> int:
    master_path = MASTERS / f"{name}.png"
    if not master_path.exists():
        sys.exit(f"missing master: {master_path.relative_to(ROOT)}")

    master = reframe(Image.open(master_path).convert("RGBA"), group.fit)
    imageset = CATALOG / group.folder / f"{name}.imageset"
    if imageset.exists():
        shutil.rmtree(imageset)
    imageset.mkdir(parents=True)

    images = []
    written = 0
    for scale in (2, 3):
        width = group.point_width * scale
        height = round(width * master.height / master.width)
        resized = master.resize((width, height), Image.LANCZOS)
        filename = f"{name}@{scale}x.png"
        encode(resized, group.palette).save(imageset / filename, "PNG", optimize=True)
        written += (imageset / filename).stat().st_size
        images.append({"filename": filename, "idiom": "universal", "scale": f"{scale}x"})

    write_json(imageset / "Contents.json", {"images": images, "info": CATALOG_INFO})
    return written


def build_texture() -> int:
    master_path = MASTERS / f"{TEXTURE}.png"
    if not master_path.exists():
        sys.exit(f"missing master: {master_path.relative_to(ROOT)}")

    # Opaque on purpose: a texture map with an alpha channel would let the
    # sphere show through wherever the generator left the edges soft.
    master = Image.open(master_path).convert("RGB").resize(TEXTURE_SIZE, Image.LANCZOS)
    imageset = CATALOG / "Textures" / f"{TEXTURE}.imageset"
    if imageset.exists():
        shutil.rmtree(imageset)
    imageset.mkdir(parents=True)

    filename = f"{TEXTURE}.png"
    master.save(imageset / filename, "PNG", optimize=True)
    # No "scale" key — Xcode reads that as a single-scale (unscaled) asset,
    # which is what a texture map wants.
    write_json(
        imageset / "Contents.json",
        {"images": [{"filename": filename, "idiom": "universal"}], "info": CATALOG_INFO},
    )
    return (imageset / filename).stat().st_size


def main() -> None:
    total = 0
    for group in GROUPS:
        folder = CATALOG / group.folder
        folder.mkdir(parents=True, exist_ok=True)
        # A folder without `provides-namespace` keeps asset names flat, so the
        # Swift side says `Image("planet-mars")`, not `Image("Planets/…")`.
        write_json(folder / "Contents.json", {"info": CATALOG_INFO})
        for name in group.names:
            total += build_imageset(group, name)
        print(f"{group.folder}: {len(group.names)} imagesets")

    (CATALOG / "Textures").mkdir(parents=True, exist_ok=True)
    write_json(CATALOG / "Textures" / "Contents.json", {"info": CATALOG_INFO})
    total += build_texture()
    print("Textures: 1 imageset")
    print(f"total: {total / 1024 / 1024:.2f} MB of PNG in the catalog")


if __name__ == "__main__":
    main()
