# Asset brief — generated imagery for Lumina

Every asset below is **one self-contained prompt**. Copy the block, paste it,
generate. Nothing to assemble, no preamble to remember, no placeholder to
fill in — the style rules are already written into each one, which is the
only reliable way to get twenty-six images that look like a set.

Written against the design board (dark presentation, cream app screens, deep
navy chart disc, celestial hero imagery).

**26 assets:** 10 planets · 12 constellations · 3 empty states · 1 moon texture.

> **Status: generated and wired in.** All 26 masters live in `assets/`, the
> catalog slots are derived from them by `scripts/build_image_assets.py`, and
> every one is on screen somewhere — see [Where each asset
> landed](#where-each-asset-landed) at the end. The prompts stay here because
> they are how you regenerate or replace one without the set drifting.

---

## Do I need to attach reference images?

**No — not to start.** Every prompt here is written to stand alone. You can
generate all twenty-six from text and get usable results.

But there are two places where attaching an image measurably beats text, and
both are worth the extra minute:

**1. Set A, after the first planet — attach your own anchor.** Text can
describe "key light from the upper left at 45 degrees" perfectly and the
model will still drift a few degrees per generation. Ten planets drifting
independently is exactly the failure this brief exists to prevent. So:

- Generate **A5 Jupiter first**. It is the best anchor in the set — a full
  sphere with real surface detail, no rings to complicate the framing, no
  corona to break the 80%-of-frame rule.
- Regenerate it until you genuinely like it. This one image sets the look of
  the other nine.
- For A1–A4 and A6–A10, attach that Jupiter render and append this line to
  the prompt:

  ```
  Match the attached reference image exactly for lighting direction, sphere
  size in frame, margin, finish, and overall colour treatment. Only the
  subject changes.
  ```

**2. Set B — attach a real star chart per sign.** The app's claim is real
astronomy, and image models are weak at reproducing specific star patterns
from a name alone. Pull the constellation from any star atlas or planetarium
app (Stellarium exports these free), attach it, and the prompt below becomes
a *restyling* job rather than a recall job. That is a much easier ask and it
is the difference between a real pattern and a plausible-looking one.

**Optionally, Set C — attach the design board.** One screenshot of the board
you sent me, attached to all three prompts, with:

```
Match the visual language of the attached reference: same restraint, same
line weight, same colour discipline. Do not copy any layout or element from
it.
```

**One thing not to attach: a NASA photograph.** Not for reference, not for
"just the colours". It drags every generation toward photorealism and back
into the stock-planet look the whole visual identity is positioned against —
and it re-introduces the licensing question the "generated, not stock" rule
exists to close. Reference only images **you generated for this app**.

---

## Read this before generating anything

**1. Consistency beats quality.** These objects appear side by side — four
planets in one transit list, ten in a chart legend. One rendered at a
different scale, or lit from a different side, ruins the set no matter how
good it looks alone. Never edit the style language inside a block to "improve
the wording" — paraphrasing between generations is the single biggest source
of inconsistent lighting.

**2. Do not generate the Moon.** `MoonSphere3DView` already renders a real
sphere in SceneKit whose terminator is driven by the actual Sun–Moon–Earth
phase angle from the ephemeris. A static moon image would show the wrong
phase on most nights, and "we don't fake the sky" is the app's entire
positioning. The one thing worth generating here is a *surface texture* for
that existing sphere — see Set D.

**3. Generated is fine; stock is not.** `ROADMAP.md`'s brand pillar is
"custom illustration only — if stock clipart is present, it ships as a bug."
Something you generated for this app is custom. Do not paste in NASA imagery
or stock photography: NASA's is public domain but reads as someone else's
app, and stock planets are precisely the category tell Lumina is positioned
against.

**4. Astronomically plausible, not photographic.** Mars should be rust with a
faint polar cap; Jupiter banded with the Red Spot; Uranus featureless cyan.
Getting these right is cheap and it is the same promise the chart maths
makes. But keep them rendered/editorial rather than trying to pass as
telescope photography — an illustration that's honestly an illustration ages
better than a fake photo.

---

## The palette

These hexes are already inside every prompt. They are the app's real tokens
(`Lumina/Design/Tokens/LuminaColors.swift`), listed here so you can check a
result against them.

| Role | Hex | Use |
|---|---|---|
| Midnight | `#0B1437` | the chart disc, celestial backdrops |
| Ink black | `#1A1A1F` | text on light |
| Parchment | `#F5F0E6` | card surfaces, glyphs on dark |
| Muted gold | `#C9A96E` | the accent — rims, constellation lines |
| Celestial blue | `#3D5A8C` | secondary accent |
| Blush | `#E5C8C2` | warmth |

**Never** a purple gradient. The brand line is "navy, never purple" — it is
the single most common tell of a generic astrology app, and the whole visual
identity is built to avoid it.

---

# Set A — Planet spheres (10 assets)

**Where they go:** planet detail hero, transit detail, aspect rows.
**Output:** 1024×1024 PNG, transparent background.
**Generate A5 Jupiter first** and use it as the reference for the rest.

---

### A5 — `planet-jupiter` · generate this one first

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Jupiter: a large banded gas giant, horizontal cream and ochre
cloud bands with turbulent feathered edges, one oval deep-red storm sitting in
the lower third.
```

---

### A1 — `planet-sun`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is the Sun: a warm golden sphere with a soft luminous corona
bleeding just past its edge, the surface faintly granular. Dominant colour warm
gold #C9A96E shading to pale cream at the centre. The corona is soft and close
to the surface, not a burst of rays.
```

---

### A2 — `planet-mercury`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Mercury: a heavily cratered rocky sphere in cool grey-brown,
covered in dense fine craters of varied size, with no atmosphere and no
atmospheric rim.
```

---

### A3 — `planet-venus`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Venus: a smooth featureless sphere wrapped in thick creamy
pale-yellow cloud, with soft horizontal banding barely visible and no surface
detail showing through.
```

---

### A4 — `planet-mars`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Mars: a rust-red sphere with subtle darker surface mottling and
one small off-white polar cap at the top.
```

---

### A6 — `planet-saturn`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. Square
composition, 1024x1024.

The subject is Saturn: a pale gold banded sphere with a thin flat ring system
tilted about 20 degrees, the rings finely striated and semi-transparent where
they pass in front of the planet. The rings may reach the frame edge; the
planet itself fills about 55% of the frame and still reads as the subject.
```

> Saturn is the one framing exception — the rings need the room, so this
> block asks for 55% rather than 80%. Everything else about it matches.

---

### A7 — `planet-uranus`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Uranus: an almost featureless pale cyan sphere with the faintest
hint of banding, and a very thin vertical ring seen nearly edge-on.
```

---

### A8 — `planet-neptune`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Neptune: a deep azure sphere with faint darker horizontal bands
and one small bright white cloud streak.
```

---

### A9 — `planet-pluto`

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Pluto: a mottled sphere in tan, charcoal and off-white, with one
large pale heart-shaped lighter region, no atmosphere and no atmospheric rim.
```

---

### A10 — `planet-earth` · optional

```
Editorial 3D render of a single celestial body, centered, isolated on a fully
transparent background. Premium magazine illustration style — not photographic,
not cartoon. Soft global illumination with one clear key light from the upper
left at roughly 45 degrees, and a faint cool rim light from the lower right at
about 15% strength. No cast shadow, no ground plane, no lens flare, no
starfield, no text, no border, no watermark, no UI. Matte finish with subtle
surface detail; avoid glossy specular highlights. Muted, desaturated palette in
the family of deep navy #0B1437, warm gold #C9A96E, and cream #F5F0E6. The
sphere fills about 80% of the frame with even margin on all sides. Square
composition, 1024x1024.

The subject is Earth seen from space: blue oceans, muted ochre-green landmasses,
thin white cloud swirls, and a faint atmospheric blue rim.
```

> Earth is last and optional — nothing in the app displays it. The chart
> doesn't place Earth. Generate it only if you want it for marketing.

---

**Consistency check before you accept Set A.** Open all ten side by side. The
key light must hit the same upper-left quadrant on every one, and the spheres
must be the same size in frame (Saturn excepted). If one is off, regenerate
that one alone against the Jupiter anchor — never adjust the other nine to
match the odd one out.

---

# Set B — Zodiac constellation avatars (12 assets)

**Where they go:** the circular avatars in the People list, keyed to each
person's Sun sign.
**Output:** 512×512 PNG, transparent background.

These are flat line art, not 3D renders — a different style block entirely.

**Accuracy matters here.** The app's claim is real astronomy; a wrong star
pattern is a small lie in the same family as a wrong planet position. Each
block names the actual asterism, and attaching a star chart (see the
reference-images section above) is the single highest-leverage thing you can
do for this set. Check each result against a chart before accepting it.

> Filenames use the **astrological** sign names because that's what the app
> keys on. The prompts use the **astronomical** constellation names
> (Scorpius, Capricornus) because models produce far more accurate star
> patterns from those.

---

### B1 — `constellation-aries`

```
Minimal constellation line art of the Aries constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Aries is a
short, sparse pattern of four stars forming a bent hook or shallow zigzag —
not a drawing of a ram. Warm gold #C9A96E on a fully transparent background.
Elegant, sparse, astronomical — the real star pattern, never a pictorial
illustration of the animal or figure. Even visual weight, centered in the
square with generous margin. No text, no labels, no border, no circle frame,
no glow, no background. Flat 2D vector-like illustration, 512x512.
```

---

### B2 — `constellation-taurus`

```
Minimal constellation line art of the Taurus constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Taurus is a
V-shaped cluster of stars forming the face, with the brightest star at one arm
of the V, and two long lines extending outward from the V as the horns. Warm
gold #C9A96E on a fully transparent background. Elegant, sparse, astronomical —
the real star pattern, never a pictorial illustration of the animal or figure.
Even visual weight, centered in the square with generous margin. No text, no
labels, no border, no circle frame, no glow, no background. Flat 2D vector-like
illustration, 512x512.
```

---

### B3 — `constellation-gemini`

```
Minimal constellation line art of the Gemini constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Gemini is two
roughly parallel columns of stars running side by side, joined near the top by
two bright stars. Warm gold #C9A96E on a fully transparent background. Elegant,
sparse, astronomical — the real star pattern, never a pictorial illustration of
the figures. Even visual weight, centered in the square with generous margin.
No text, no labels, no border, no circle frame, no glow, no background. Flat 2D
vector-like illustration, 512x512.
```

---

### B4 — `constellation-cancer`

```
Minimal constellation line art of the Cancer constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Cancer is a
faint, sparse inverted Y shape of four main stars. Warm gold #C9A96E on a fully
transparent background. Elegant, sparse, astronomical — the real star pattern,
never a pictorial illustration of the crab. Even visual weight, centered in the
square with generous margin. No text, no labels, no border, no circle frame, no
glow, no background. Flat 2D vector-like illustration, 512x512.
```

---

### B5 — `constellation-leo`

```
Minimal constellation line art of the Leo constellation, drawn as small filled
circles for stars connected by thin straight hairlines. Leo opens with the
Sickle — a curved hook shaped like a backwards question mark — with a bright
star at its base, and closes with a triangle of stars at the opposite end. Warm
gold #C9A96E on a fully transparent background. Elegant, sparse, astronomical —
the real star pattern, never a pictorial illustration of the lion. Even visual
weight, centered in the square with generous margin. No text, no labels, no
border, no circle frame, no glow, no background. Flat 2D vector-like
illustration, 512x512.
```

---

### B6 — `constellation-virgo`

```
Minimal constellation line art of the Virgo constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Virgo is a large
sprawling Y shape, with its brightest star at the base of the stem. Warm gold
#C9A96E on a fully transparent background. Elegant, sparse, astronomical — the
real star pattern, never a pictorial illustration of the figure. Even visual
weight, centered in the square with generous margin. No text, no labels, no
border, no circle frame, no glow, no background. Flat 2D vector-like
illustration, 512x512.
```

---

### B7 — `constellation-libra`

```
Minimal constellation line art of the Libra constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Libra is a
lopsided quadrilateral — a tilted four-star box — with two fainter stars
trailing from its lower corners. Warm gold #C9A96E on a fully transparent
background. Elegant, sparse, astronomical — the real star pattern, never a
pictorial illustration of scales. Even visual weight, centered in the square
with generous margin. No text, no labels, no border, no circle frame, no glow,
no background. Flat 2D vector-like illustration, 512x512.
```

---

### B8 — `constellation-scorpio`

```
Minimal constellation line art of the Scorpius constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Scorpius is a
long sweeping curve like a fish hook or the letter J, with a bright star at the
heart of the curve and a tightly curled tail at the end. Warm gold #C9A96E on a
fully transparent background. Elegant, sparse, astronomical — the real star
pattern, never a pictorial illustration of the scorpion. Even visual weight,
centered in the square with generous margin. No text, no labels, no border, no
circle frame, no glow, no background. Flat 2D vector-like illustration,
512x512.
```

---

### B9 — `constellation-sagittarius`

```
Minimal constellation line art of the Sagittarius constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Sagittarius
contains the Teapot asterism — a clear teapot outline with a triangular lid, a
handle on one side and a spout on the other. Warm gold #C9A96E on a fully
transparent background. Elegant, sparse, astronomical — the real star pattern,
never a pictorial illustration of an archer or a centaur. Even visual weight,
centered in the square with generous margin. No text, no labels, no border, no
circle frame, no glow, no background. Flat 2D vector-like illustration,
512x512.
```

---

### B10 — `constellation-capricorn`

```
Minimal constellation line art of the Capricornus constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Capricornus is a
wide, flattened triangle — a shallow boat or arrowhead shape, broad and low.
Warm gold #C9A96E on a fully transparent background. Elegant, sparse,
astronomical — the real star pattern, never a pictorial illustration of a goat
or a sea-goat. Even visual weight, centered in the square with generous margin.
No text, no labels, no border, no circle frame, no glow, no background. Flat 2D
vector-like illustration, 512x512.
```

---

### B11 — `constellation-aquarius`

```
Minimal constellation line art of the Aquarius constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Aquarius is a
loose, wide zigzag of faint stars, with a small compact Y-shaped group of four
stars near the centre. Warm gold #C9A96E on a fully transparent background.
Elegant, sparse, astronomical — the real star pattern, never a pictorial
illustration of a water bearer or an urn. Even visual weight, centered in the
square with generous margin. No text, no labels, no border, no circle frame, no
glow, no background. Flat 2D vector-like illustration, 512x512.
```

---

### B12 — `constellation-pisces`

```
Minimal constellation line art of the Pisces constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Pisces is two
long strands of stars meeting at a shallow V, with one strand ending in a small
ring of five stars. Warm gold #C9A96E on a fully transparent background.
Elegant, sparse, astronomical — the real star pattern, never a pictorial
illustration of fish. Even visual weight, centered in the square with generous
margin. No text, no labels, no border, no circle frame, no glow, no background.
Flat 2D vector-like illustration, 512x512.
```

---

# Set C — Onboarding / empty-state illustrations (3 assets, optional)

**Where they go:** the birth-info empty state, the "no people yet" state, and
the chart-reveal moment.
**Output:** 1536×1024 PNG, transparent background.

---

### C1 — `empty-birth-info`

```
Sparse editorial illustration for a premium astrology app. A simple
line-drawn armillary sphere resting at a slight angle, with a few loose stars
scattered around it. Drawn in thin warm gold #C9A96E and cream #F5F0E6 lines on
a fully transparent background, with deep navy #0B1437 used only for small
filled accents. Calm, minimal, generous negative space, wellness-editorial
rather than mystical. No purple, no neon, no glow, no text, no border, no
background fill. Wide composition, 1536x1024.
```

---

### C2 — `empty-people`

```
Sparse editorial illustration for a premium astrology app. Two overlapping thin
circles like a Venn diagram, each ringed with a handful of small stars. Drawn in
thin warm gold #C9A96E and cream #F5F0E6 lines on a fully transparent
background, with deep navy #0B1437 used only for small filled accents. Calm,
minimal, generous negative space, wellness-editorial rather than mystical. No
purple, no neon, no glow, no text, no border, no background fill. Wide
composition, 1536x1024.
```

---

### C3 — `reveal-signature`

```
Sparse editorial illustration for a premium astrology app. A thin crescent moon
with three concentric dotted orbit rings around it and a scatter of small stars.
Drawn in thin warm gold #C9A96E and cream #F5F0E6 lines on a fully transparent
background, with deep navy #0B1437 used only for small filled accents. Calm,
minimal, generous negative space, wellness-editorial rather than mystical. No
purple, no neon, no glow, no text, no border, no background fill. Wide
composition, 1536x1024.
```

---

# Set D — Moon surface texture (1 asset)

The only Moon asset worth making. This is an **equirectangular texture map**
wrapped onto the existing SceneKit sphere, so the app keeps computing the real
phase and just gets a better surface than the current procedural one.

**Output:** 2048×1024 PNG, **opaque** — this is the one asset that is not
transparent.

---

### D1 — `moon-surface`

```
Equirectangular texture map of the full lunar surface for 3D wrapping, 2:1
aspect ratio, seamless at the left and right edges. Desaturated grey-cream
tones with realistic maria as darker grey regions and lighter cratered
highlands. Evenly lit with completely flat ambient lighting and absolutely no
shadows, no terminator, no black limb — this is a flat surface texture, not a
photograph of the moon in space. No stars, no background, no text, no border.
2048x1024.
```

**"No terminator" is the critical instruction.** Any baked-in shading fights
the real one SceneKit computes from the ephemeris, and the moon will look
wrong on most nights. If the result has a dark limb or a visible day/night
line, regenerate — it is not usable, however good it looks on its own.

---

## After generation

1. **Confirm transparency.** Open each on both a white and a black
   background. If there is a halo, a grey box, or a soft rectangle, the alpha
   is wrong.

   If the model refuses to give real transparency, generate on flat magenta
   `#FF00FF` and key it out — never on black or white, both of which appear
   inside the planet artwork itself and will punch holes in the subject.

2. **Trim and centre.** Crop to the object's bounds, then re-pad to a square
   with even margin. Sets A and B must be optically centred or they will
   jitter when the app swaps between them in a list.

3. **Drop the master in `assets/`**, named exactly as the heading of its
   block above, at whatever size it came out of the generator. Nothing in
   `assets/` is loaded by the app — these are the originals, and they are the
   only file you ever edit by hand.

4. **Run the build script.** It does steps 2–4 of the old manual process —
   trim, centre, scale, encode — and writes the `.imageset` folders and their
   `Contents.json`:

   ```sh
   pip install Pillow
   python3 scripts/build_image_assets.py
   ```

   | | Set A (planets) | Set B (constellations) | Set C (illustrations) | Set D (texture) |
   |---|---|---|---|---|
   | `@2x` | 256 px | 128 px | 512 px wide | — |
   | `@3x` | 384 px | 192 px | 768 px wide | — |
   | single scale | — | — | — | 1024×512 |
   | re-framed | no — already a matched set | trimmed and re-centred | margin trimmed | no |
   | encoding | 8-bit RGBA | 256-colour palette | 256-colour palette | 8-bit RGB, opaque |

   No `@1x`: the deployment target is iOS 26, so every device that can install
   Lumina has a Retina screen and a `@1x` slot would be dead weight.

   The planets keep full RGBA because their soft alpha glows — the Sun's
   corona above all — band visibly under a palette. The line art doesn't, and
   quantises to about a fifth the size with no visible change. The set lands
   at ~2.7 MB of PNG in the catalog; the old ~2 MB target assumed `pngquant`
   could take the spheres too, and it can't without wrecking the corona.

5. **Check what the script wrote.** It prints a per-group count and the total.
   `ImageAssetTests` then fails the build if any name in `LuminaImageAsset`
   doesn't resolve against the compiled catalog, so a mistyped or missing
   file can't reach a device silently.

---

## What I am *not* asking you to generate, and why

| Not needed | Because |
|---|---|
| Moon phase images | `MoonSphere3DView` computes the real phase; a static image would be wrong most nights |
| Starfields / backgrounds | `LuminaStarfield` is procedural, deterministic, and honours Reduce Motion |
| Zodiac + planet glyphs | Unicode, already correct, and they scale with Dynamic Type |
| App icon | Generated by `scripts/generate_app_icon.mjs` |
| Chart wheel | Drawn live from the real chart in `ChartWheelView` |
| Tab bar icons | SF Symbols — free, consistent, and they inherit Dynamic Type |

The pattern: anything derived from **your actual chart** stays computed.
Images are only for things that are the same for everyone.

---

## Where each asset landed

Every asset is on a real screen. Nothing here is decoration held in reserve.

| Asset | Surface | Notes |
|---|---|---|
| `planet-*` (9 chart bodies) | `PlanetDetailSheet` header | The hero of a placement's reading, via `PlanetMark` |
| `planet-*` | `ForecastView` rows | The transiting body, leading each upcoming-date row |
| `planet-*` | `TodayTransparencySheet` rows | The transiting body, beside the "why this line" detail |
| `planet-*` | `RetrogradeCard` | The bodies currently walking backwards, as a strip |
| `planet-earth` | `TodayTransparencySheet` footer | Where the positions are measured *from* — geocentric, said plainly |
| `constellation-*` (12) | `PeopleHubView` avatars | Keyed to each person's Sun sign, read in their own birth zone |
| `empty-birth-info` | Chart hub + Today hub, missing birth data | Both routes to the same "add your birth info" state |
| `empty-people` | `PeopleHubView` empty state | |
| `reveal-signature` | `DailyRevealVeilCard` | The pre-reveal face of the daily reading |
| `moon-surface` | `MoonSphere3DView` | Wrapped on the SceneKit sphere; the phase stays computed |

Two things stay glyphs on purpose: the **Moon** in any planet row (its real
phase is rendered live — a static Moon would be wrong most nights) and every
**zodiac sign** in chart text (Unicode, scales with Dynamic Type). `PlanetMark`
falls back to the glyph for anything without art, so a body the backend adds
later renders as a glyph rather than a hole.
