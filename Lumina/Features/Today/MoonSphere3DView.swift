import SceneKit
import SwiftUI

/// An interactive, physically-lit 3D Moon — drag to orbit, pinch to zoom
/// (via `SCNView.allowsCameraControl`, not custom gesture code). The
/// terminator (light/dark boundary) is driven by the real Sun-Moon-Earth
/// phase angle from the ephemeris backend, never faked or merely decorative.
///
/// All SceneKit types (`SCNScene`, `SCNNode`, …) are non-Sendable reference
/// types, but `makeUIView`/`updateUIView` are called on `@MainActor` by
/// SwiftUI itself, and the whole scene graph is built and only ever touched
/// on that same call — nothing crosses an actor boundary here.
struct MoonSphere3DView: UIViewRepresentable {
    let phase: MoonPhaseResult
    let reduceMotion: Bool

    private static let moonRadius: CGFloat = 1
    private static let lightDistance: Float = 8
    private static let cameraDistance: Float = 3.5
    private static let spinDuration: TimeInterval = 24

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        let scene = SCNScene()

        let moonNode = Self.makeMoonNode()
        scene.rootNode.addChildNode(moonNode)
        for light in Self.makeLightNodes(forAngle: phase.angle) {
            scene.rootNode.addChildNode(light)
        }
        scene.rootNode.addChildNode(Self.makeCameraNode())

        if !reduceMotion {
            let spin = SCNAction.repeatForever(
                .rotateBy(x: 0, y: .pi * 2, z: 0, duration: Self.spinDuration)
            )
            moonNode.runAction(spin)
        }

        view.scene = scene
        view.backgroundColor = .clear
        // The key trick for an "immersive" feel with zero custom gesture
        // code: SceneKit's built-in camera rig gives free drag-to-orbit and
        // pinch-to-zoom for the whole scene.
        view.allowsCameraControl = true
        // We place our own key + ambient lights below, so don't let SceneKit
        // add its default headlight on top of them.
        view.autoenablesDefaultLighting = false
        return view
    }

    /// No-op: `phase` is fixed for the lifetime of the sheet that presents
    /// this view (it's passed in once from `MoonPhaseCard`'s already-loaded
    /// `@State`), so there is never a new phase to re-light the scene for.
    func updateUIView(_ view: SCNView, context: Context) { }

    // MARK: - Scene construction

    private static func makeMoonNode() -> SCNNode {
        let sphere = SCNSphere(radius: moonRadius)
        sphere.segmentCount = 96
        let material = SCNMaterial()
        material.diffuse.contents = makeMoonTexture()
        // A real rocky surface has almost no specular highlight; keep it
        // matte so the lit/dark split reads as terrain, not a glossy ball.
        material.specular.contents = UIColor(white: 0.05, alpha: 1)
        material.lightingModel = .lambert
        sphere.materials = [material]
        return SCNNode(geometry: sphere)
    }

    /// Real trigonometry, not decoration: `phase.angle` is the genuine
    /// Sun-Moon-Earth phase angle from the ephemeris backend (0° = new,
    /// 180° = full), and it directly determines where the key light sits.
    ///
    /// The camera sits on the +Z axis looking at the origin (see
    /// `makeCameraNode`), so the camera-visible hemisphere of the moon is
    /// the one facing +Z. For the terminator to be correct:
    ///   - `angle == 0` (new moon) must put the light BEHIND the sphere
    ///     (negative Z) so the visible face is dark.
    ///   - `angle == 180` (full moon) must put the light on the SAME side
    ///     as the camera (positive Z) so the visible face is fully lit.
    ///
    /// A naive `z = cos(angleRad) * radius` gets this backwards (it puts
    /// the light in front at angle 0 and behind at angle 180 — full moon
    /// would render dark, new moon would render bright). Negating that
    /// term (`z = -cos(angleRad) * radius`) gives the physically correct
    /// mapping: cos(0) = 1 → z = -radius (behind, dark near face, new
    /// moon ✓); cos(180°) = -1 → z = +radius (camera side, lit near face,
    /// full moon ✓). 90°/270° land the light on the X axis, correctly
    /// splitting the sphere into lit/dark halves for the quarters.
    private static func makeLightNodes(forAngle angleDegrees: Double) -> [SCNNode] {
        let angleRad = angleDegrees * .pi / 180
        let key = SCNLight()
        key.type = .directional
        key.intensity = 1_000
        key.color = UIColor(white: 0.96, alpha: 1)
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(
            sin(Float(angleRad)) * lightDistance,
            0,
            -cos(Float(angleRad)) * lightDistance
        )
        keyNode.look(at: SCNVector3Zero)

        // Low-intensity ambient fill so the unlit hemisphere reads as
        // shadowed rock, not a pure-black silhouette — a subtle cool-gray
        // tint, matching the brand's desaturated, non-mystical moon.
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 100
        ambient.color = UIColor(red: 0.55, green: 0.58, blue: 0.68, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient

        return [keyNode, ambientNode]
    }

    private static func makeCameraNode() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 40
        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(0, 0, cameraDistance)
        node.look(at: SCNVector3Zero)
        return node
    }

    // MARK: - Procedural texture

    /// Generates a desaturated, silvery moon-surface texture at runtime —
    /// no downloaded or bundled image, in the same "draw it in code" spirit
    /// as `scripts/generate_app_icon.mjs`. Craters are placed with a fixed
    /// seed so the texture is stable across renders and app launches, not
    /// re-randomized every time (which would look like flickering noise if
    /// this view were ever rebuilt).
    private static func makeMoonTexture() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            drawBase(in: cg, size: size)
            drawCraters(in: cg, size: size)
        }
    }

    private static func drawBase(in cg: CGContext, size: CGSize) {
        let colors = [
            UIColor(white: 0.82, alpha: 1).cgColor,
            UIColor(white: 0.62, alpha: 1).cgColor,
        ]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors as CFArray,
            locations: [0, 1]
        ) else {
            // Extremely unlikely (fixed, valid inputs above) — fall back to
            // a flat fill rather than force-unwrapping the gradient.
            cg.setFillColor(UIColor(white: 0.72, alpha: 1).cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            return
        }
        let center = CGPoint(x: size.width * 0.42, y: size.height * 0.4)
        cg.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: CGPoint(x: size.width / 2, y: size.height / 2),
            endRadius: size.width * 0.75,
            options: [.drawsAfterEndLocation]
        )
    }

    /// Simple deterministic hash-based PRNG (splitmix-style) so crater
    /// placement is fixed across renders without reaching for
    /// `Int.random`/`Double.random`, which reseed on every call.
    private static func pseudoRandom(_ seed: Int) -> Double {
        var value = UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15
        value ^= value >> 30
        value = value &* 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        return Double(value % 1_000) / 1_000
    }

    private static func drawCraters(in cg: CGContext, size: CGSize) {
        let craterCount = 42
        for index in 0..<craterCount {
            let px = pseudoRandom(index * 3 + 1)
            let py = pseudoRandom(index * 3 + 2)
            let ps = pseudoRandom(index * 3 + 3)
            let x = px * size.width
            let y = py * size.height
            let radius = 8 + ps * 34
            let shade = 0.28 + pseudoRandom(index * 7 + 5) * 0.18
            drawCrater(in: cg, center: CGPoint(x: x, y: y), radius: radius, shade: shade)
        }
    }

    private static func drawCrater(in cg: CGContext, center: CGPoint, radius: Double, shade: Double) {
        let colors = [
            UIColor(white: shade, alpha: 0.85).cgColor,
            UIColor(white: shade, alpha: 0).cgColor,
        ]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors as CFArray,
            locations: [0, 1]
        ) else { return }
        cg.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: CGFloat(radius),
            options: []
        )
    }
}
