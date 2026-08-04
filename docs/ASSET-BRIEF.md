# Asset brief — generated imagery for Lumina

Copy-paste prompts for an image model, plus what to do with the results.

Written against the design board (dark presentation, cream app screens, deep
navy chart disc, celestial hero imagery). The app currently ships **zero**
image assets — every visual is procedural (`Canvas`, SceneKit) or an SF
Symbol — so everything here is net new and nothing gets replaced by accident.

---

## Read this before generating anything

**1. Consistency beats quality.** These objects appear side by side — four
planets in one transit list, ten in a chart legend. One rendered at a
different scale, or lit from a different side, ruins the set no matter how
good it looks alone. The Style Preamble below exists for exactly this: paste
it before every planet prompt, unchanged, every time.

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

Every prompt should quote these. They are the app's real tokens
(`Lumina/Design/Tokens/LuminaColors.swift`).

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

## Style Preamble

**Paste this verbatim at the top of every prompt in Set A.** Do not
paraphrase it between generations — small wording changes are what produce
inconsistent lighting.

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
```

---

## Set A — Planet spheres (10 assets)

**Where they go:** planet detail hero, transit detail, aspect rows.
**Output:** 1024×1024 PNG, transparent.

For each, paste the Style Preamble, then one line below.

| # | File | Prompt line to append |
|---|---|---|
| A1 | `planet-sun` | `The subject is the Sun: a warm golden sphere with a soft luminous corona bleeding just past its edge, surface faintly granular. Dominant colour warm gold #C9A96E shading to pale cream at the centre.` |
| A2 | `planet-mercury` | `The subject is Mercury: a small heavily cratered rocky sphere, cool grey-brown, dense fine craters of varied size, no atmosphere.` |
| A3 | `planet-venus` | `The subject is Venus: a smooth featureless sphere wrapped in thick creamy pale-yellow cloud, soft banding barely visible, no surface detail.` |
| A4 | `planet-mars` | `The subject is Mars: a rust-red sphere with subtle darker surface mottling and one small off-white polar cap at the top.` |
| A5 | `planet-jupiter` | `The subject is Jupiter: a large banded gas giant, horizontal cream and ochre cloud bands with turbulent edges, one oval deep-red storm in the lower third.` |
| A6 | `planet-saturn` | `The subject is Saturn: a pale gold banded sphere with a thin flat ring system tilted about 20 degrees, rings finely striated and semi-transparent where they cross in front of the planet. The rings may extend to the frame edge; the planet still reads as the subject.` |
| A7 | `planet-uranus` | `The subject is Uranus: an almost featureless pale cyan sphere with the faintest hint of banding and a very thin vertical ring seen nearly edge-on.` |
| A8 | `planet-neptune` | `The subject is Neptune: a deep azure sphere with faint darker bands and one small bright white cloud streak.` |
| A9 | `planet-pluto` | `The subject is Pluto: a small mottled sphere in tan, charcoal and off-white, with one large pale heart-shaped lighter region, no atmosphere.` |
| A10 | `planet-earth` | `The subject is Earth seen from space: blue oceans, muted ochre-green landmasses, thin white cloud swirls, a faint atmospheric blue rim.` |

> Earth is last because nothing displays it yet. Generate it only if you want
> it for marketing — the chart doesn't place Earth.

**Consistency check before you accept the set:** open all ten side by side.
The key light must hit the same upper-left quadrant on every one, and the
spheres must be the same size in frame. If one is off, regenerate that one
alone — do not adjust the others to match it.

---

## Set B — Zodiac constellation avatars (12 assets)

**Where they go:** the circular avatars in the People list, keyed to each
person's Sun sign.
**Output:** 512×512 PNG, transparent.

These are line art, not renders — the Style Preamble does **not** apply.

```
Minimal constellation line art of the [SIGN] constellation, drawn as small
filled circles for stars connected by thin straight hairlines. Warm gold
#C9A96E on a fully transparent background. Elegant, sparse, astronomical —
the real star pattern of the constellation, not a pictorial drawing of the
animal or figure. Even visual weight, occupying a centered square with
generous margin. No text, no labels, no border, no circle frame, no glow, no
background. Flat 2D vector-like illustration, 512x512.
```

Replace `[SIGN]` with each of: **Aries, Taurus, Gemini, Cancer, Leo, Virgo,
Libra, Scorpius, Sagittarius, Capricornus, Aquarius, Pisces**.

Files: `constellation-aries` … `constellation-pisces`.

> Use the astronomical names (Scorpius, Capricornus) in the prompt — models
> produce more accurate star patterns from them than from the astrological
> forms (Scorpio, Capricorn). Name the *files* after the astrological signs,
> because that's what the app keys on.

**Accuracy matters here.** The app's claim is real astronomy. Check each
against a star chart before accepting — a wrong pattern is a small lie in the
same family as a wrong planet position.

---

## Set C — Onboarding / empty-state illustrations (3 assets, optional)

**Where they go:** the birth-info empty state, the "no friends yet" state,
and the chart-reveal moment.
**Output:** 1536×1024 PNG, transparent.

```
Sparse editorial illustration for a premium astrology app. [SUBJECT]. Drawn in
thin warm gold #C9A96E and cream #F5F0E6 lines on a fully transparent
background, with deep navy #0B1437 used only for small filled accents. Calm,
minimal, generous negative space, wellness-editorial rather than mystical. No
purple, no neon, no glow, no text, no border, no background fill. Wide
composition, 1536x1024.
```

| File | `[SUBJECT]` |
|---|---|
| `empty-birth-info` | `A simple line-drawn armillary sphere resting at an angle, a few loose stars around it` |
| `empty-people` | `Two overlapping thin circles like a Venn diagram, each ringed with a handful of small stars` |
| `reveal-signature` | `A thin crescent moon with three concentric dotted orbit rings and a scatter of small stars` |

---

## Set D — Moon surface texture (1 asset, replaces nothing)

The only Moon asset worth making. This is an **equirectangular texture map**
wrapped onto the existing SceneKit sphere, so the app keeps computing the
real phase and just gets a better surface than the current procedural one.

**Output:** 2048×1024 PNG, **opaque** (this one is not transparent).

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
the real one SceneKit computes from the ephemeris and the moon will look
wrong on most nights. If the result has a dark limb or a visible day/night
line, regenerate — it is not usable.

---

## After generation

1. **Confirm transparency.** Open on both a white and a black background. If
   there is a halo, a grey box, or a soft rectangle, the alpha is wrong.

   If the model refuses to give real transparency, generate on flat magenta
   `#FF00FF` and key it out — never on black or white, both of which appear
   in the planet artwork itself and will punch holes in the subject.

2. **Trim and centre.** Crop to the object's bounds, then re-pad to a square
   with even margin. Sets A and B must be optically centred or they will
   jitter when the app swaps between them in a list.

3. **Export the three iOS scales** from the 1024 master:

   | Suffix | Set A / C | Set B |
   |---|---|---|
   | `@1x` | 128 px | 64 px |
   | `@2x` | 256 px | 128 px |
   | `@3x` | 384 px | 192 px |

4. **Compress.** `pngquant --quality 65-85` typically drops these ~70% with
   no visible loss. Budget: the whole set should land under ~2 MB. App size
   is a real download-conversion factor and there is no reason for a 40 MB
   binary of spheres.

5. **Drop them in** `Lumina/Resources/Assets.xcassets/`, one `.imageset` per
   asset, named exactly as the File column above. Send them over and I'll
   wire them up — the code doesn't reference any of these yet.

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
