import Foundation
import Security

/// Minimal Keychain wrapper for exactly one blob of `Data`, stored under a
/// fixed service/account pair. This is deliberately not a generalized
/// Keychain library — `AuthManager` is the only caller, and it only ever
/// needs save/load/delete for one persisted `AuthSession`.
///
/// Uses `kSecClassGenericPassword` (the standard choice for small app-owned
/// secrets that aren't literally an internet password), scoped to
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so a background refresh
/// can still read the session after the device reboots but before the user
/// unlocks it again this boot, while keeping the item out of device backups
/// and off any migrated/restored device.
struct KeychainStore {
    enum StoreError: Error, Equatable, Sendable {
        case unhandledStatus(OSStatus)
    }

    private let service: String
    private let account: String

    init(service: String = "app.lumina.ios.auth", account: String = "session") {
        self.service = service
        self.account = account
    }

    /// Overwrites any existing value for this service/account with `data`.
    func save(_ data: Data) throws {
        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }
        guard addStatus == errSecDuplicateItem else {
            throw StoreError.unhandledStatus(addStatus)
        }

        // Re-assert accessibility on update so items written before the
        // `ThisDeviceOnly` tightening get upgraded on their next write.
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        guard updateStatus == errSecSuccess else {
            throw StoreError.unhandledStatus(updateStatus)
        }
    }

    /// Returns `nil` when nothing is stored yet (`errSecItemNotFound` is not
    /// an error condition for a caller doing an optional restore).
    func load() throws -> Data? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw StoreError.unhandledStatus(status)
        }
        return result as? Data
    }

    /// No-op (not an error) if nothing was stored.
    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StoreError.unhandledStatus(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
