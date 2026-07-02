import Foundation
import OSLog

/// Persists the user's `BirthData` so every feature surface — Chart tab,
/// Daily reading, Compatibility, Reflect prompts — can read from one
/// source. Onboarding writes here on completion; Settings → "Update
/// birth info" overwrites here.
///
/// SwiftData ships in the broader migration when we land that. Until
/// then, this is a tiny `UserDefaults`-backed helper following the
/// `AppRouterStorage` / `OnboardingStorage` pattern.
struct UserBirthDataStore: @unchecked Sendable {
    private enum Keys {
        static let birthData = "luminaUserBirthData"
        static let revision = "luminaUserBirthDataRevision"
    }

    /// Posted after `save()` / `clear()` change the stored birth data, so
    /// long-lived screens (Today) can refresh instead of showing stale
    /// content. Posted on the caller's thread; observers hop to the main
    /// actor themselves.
    static let didChangeNotification = Notification.Name("luminaUserBirthDataDidChange")

    static let userDefaults: UserBirthDataStore = .init(defaults: .standard)

    private let logger = Logger(subsystem: "app.lumina.ios", category: "UserBirthDataStore")
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// Monotonically increasing change token, bumped by every successful
    /// `save()` and by `clear()`. Consumers remember the revision they loaded
    /// against and reload when it moves. `UserDefaults` is thread-safe, and
    /// writes only come from user-driven main-actor flows (onboarding,
    /// Settings), so the read-increment-write never races.
    var revision: Int {
        defaults.integer(forKey: Keys.revision)
    }

    func save(_ birthData: BirthData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(birthData)
            defaults.set(data, forKey: Keys.birthData)
            bumpRevision()
        } catch {
            logger.error("failed to persist birth data: \(error.localizedDescription)")
        }
    }

    func load() -> BirthData? {
        guard let data = defaults.data(forKey: Keys.birthData) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BirthData.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: Keys.birthData)
        bumpRevision()
    }

    private func bumpRevision() {
        defaults.set(revision + 1, forKey: Keys.revision)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
