import Foundation

/// Helpers for values injected at build time via xcconfig → `Info.plist`.
///
/// When a `secrets/Config.xcconfig` variable is never defined (CI, fresh
/// clones before `scripts/inject_env.sh` runs), Xcode does NOT fail the
/// build — it leaves the reference unexpanded, so the plist value is the
/// literal string `"$(SWISS_EPH_API_SECRET)"`. A plain `!isEmpty` check
/// passes for that garbage, and the app would send the placeholder to the
/// backend as a real credential instead of failing over to its
/// `.missingConfiguration` path. Mirrors `IAPManager.isRealAPIKey`.
enum BuildConfig {
    /// Returns `raw` only when it looks like a genuinely configured value.
    /// `nil`, the empty string, and unexpanded `$(…)` xcconfig placeholders
    /// all collapse to `nil`, so callers can keep a single
    /// `guard let` + throw-missing-configuration path.
    static func realValue(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty, !raw.hasPrefix("$(") else { return nil }
        return raw
    }
}
