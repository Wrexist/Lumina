import SwiftUI

/// Every bundled image in the app, named once. Views ask for a case, never
/// for a string — a typo in `Image("planet-marss")` is a silent blank space
/// at runtime, while a typo here doesn't compile, and `ImageAssetTests`
/// checks that all of these actually resolve in the bundle.
///
/// The art itself is generated (see `docs/ASSET-BRIEF.md`), with the masters
/// in `assets/` and the catalog slots derived from them by
/// `scripts/build_image_assets.py`.
///
/// Two absences are deliberate, not gaps:
/// * **No Moon sphere.** `MoonSphere3DView` renders the real phase from the
///   ephemeris; a static moon would show the wrong one most nights. The Moon
///   asset here is a surface *texture* for that sphere.
/// * **No zodiac or planet glyphs.** Those are Unicode, already correct, and
///   they scale with Dynamic Type — an image would do neither.
enum LuminaImageAsset: String, CaseIterable, Sendable {
    // Set A — planet spheres, for the placement hero and transit rows.
    case planetSun = "planet-sun"
    case planetMercury = "planet-mercury"
    case planetVenus = "planet-venus"
    case planetEarth = "planet-earth"
    case planetMars = "planet-mars"
    case planetJupiter = "planet-jupiter"
    case planetSaturn = "planet-saturn"
    case planetUranus = "planet-uranus"
    case planetNeptune = "planet-neptune"
    case planetPluto = "planet-pluto"

    // Set B — zodiac constellation avatars, keyed to a person's Sun sign.
    case constellationAries = "constellation-aries"
    case constellationTaurus = "constellation-taurus"
    case constellationGemini = "constellation-gemini"
    case constellationCancer = "constellation-cancer"
    case constellationLeo = "constellation-leo"
    case constellationVirgo = "constellation-virgo"
    case constellationLibra = "constellation-libra"
    case constellationScorpio = "constellation-scorpio"
    case constellationSagittarius = "constellation-sagittarius"
    case constellationCapricorn = "constellation-capricorn"
    case constellationAquarius = "constellation-aquarius"
    case constellationPisces = "constellation-pisces"

    // Set C — empty-state and reveal illustrations.
    case emptyBirthInfo = "empty-birth-info"
    case emptyPeople = "empty-people"
    case revealSignature = "reveal-signature"

    // Set D — equirectangular texture for the SceneKit moon.
    case moonSurface = "moon-surface"

    /// The sphere for a chart body, or `nil` when there isn't one — the Moon
    /// (rendered live, never a static image) and anything the backend sends
    /// that we don't have art for, which falls back to the Unicode glyph
    /// rather than leaving a hole in the row.
    static func planet(_ name: String) -> LuminaImageAsset? {
        switch name {
        case "Sun": .planetSun
        case "Mercury": .planetMercury
        case "Venus": .planetVenus
        case "Earth": .planetEarth
        case "Mars": .planetMars
        case "Jupiter": .planetJupiter
        case "Saturn": .planetSaturn
        case "Uranus": .planetUranus
        case "Neptune": .planetNeptune
        case "Pluto": .planetPluto
        default: nil
        }
    }

    /// The constellation for a tropical sign name, as `ChartGlyphs.signOrder`
    /// spells it.
    static func constellation(sign: String) -> LuminaImageAsset? {
        switch sign {
        case "Aries": .constellationAries
        case "Taurus": .constellationTaurus
        case "Gemini": .constellationGemini
        case "Cancer": .constellationCancer
        case "Leo": .constellationLeo
        case "Virgo": .constellationVirgo
        case "Libra": .constellationLibra
        case "Scorpio": .constellationScorpio
        case "Sagittarius": .constellationSagittarius
        case "Capricorn": .constellationCapricorn
        case "Aquarius": .constellationAquarius
        case "Pisces": .constellationPisces
        default: nil
        }
    }

    var image: Image {
        Image(rawValue, bundle: Self.bundle)
    }

    /// UIKit access, for the SceneKit material that can't take a SwiftUI
    /// `Image`. `nil` means the asset is missing from the catalog — callers
    /// fall back rather than crash.
    var uiImage: UIImage? {
        UIImage(named: rawValue, in: Self.bundle, with: nil)
    }

    /// Resolved from a type in this module rather than `Bundle.main`, so the
    /// lookup works the same from the app and from a test bundle that has no
    /// app host.
    private static var bundle: Bundle {
        Bundle(for: LuminaBundleToken.self)
    }
}

/// Anchor for `Bundle(for:)` — needs to be a class, and needs to live in the
/// app target so the bundle it resolves to is the one holding the catalog.
private final class LuminaBundleToken {}
