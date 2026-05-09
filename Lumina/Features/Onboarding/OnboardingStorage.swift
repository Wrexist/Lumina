import Foundation

/// Persistence seam for `OnboardingState`. UserDefaults in production,
/// in-memory in tests. Mirrors the `AppRouterStorage` shape — a small
/// protocol-backed struct that's `@unchecked Sendable` because the
/// concrete backings carry their own thread safety.
struct OnboardingStorage: @unchecked Sendable {
    private enum Keys {
        static let snapshot = "luminaOnboardingSnapshot"
    }

    static let userDefaults: OnboardingStorage = .init(backing: UserDefaultsBacking())

    private let backing: any OnboardingStorageBacking

    func load() -> OnboardingSnapshot {
        guard let data = backing.data(for: Keys.snapshot) else {
            return OnboardingSnapshot()
        }
        return (try? JSONDecoder().decode(OnboardingSnapshot.self, from: data)) ?? OnboardingSnapshot()
    }

    func save(_ snapshot: OnboardingSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        backing.set(data: data, for: Keys.snapshot)
    }

    func clear() {
        backing.set(data: nil, for: Keys.snapshot)
    }

    static func inMemory() -> OnboardingStorage {
        .init(backing: InMemoryBacking())
    }
}

private protocol OnboardingStorageBacking: Sendable {
    func data(for key: String) -> Data?
    func set(data value: Data?, for key: String)
}

private struct UserDefaultsBacking: OnboardingStorageBacking {
    func data(for key: String) -> Data? {
        UserDefaults.standard.data(forKey: key)
    }
    func set(data value: Data?, for key: String) {
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

private final class InMemoryBacking: OnboardingStorageBacking, @unchecked Sendable {
    private var values: [String: Data] = [:]
    private let queue = DispatchQueue(label: "app.lumina.OnboardingStorage.memory")

    func data(for key: String) -> Data? {
        queue.sync { values[key] }
    }
    func set(data value: Data?, for key: String) {
        queue.sync {
            if let value {
                values[key] = value
            } else {
                values.removeValue(forKey: key)
            }
        }
    }
}
