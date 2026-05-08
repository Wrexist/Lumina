import Foundation

/// All premium entitlements gated behind RevenueCat. Identifiers must match
/// the entitlement IDs configured in the RevenueCat dashboard.
enum Entitlement: String, CaseIterable, Sendable {
    case luminaPlus = "lumina_plus"
}
