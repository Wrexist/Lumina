import Foundation

/// A single local notification, ready to schedule — produced by
/// `TransitNotificationPlanner` and consumed by `TransitNotificationScheduler`.
/// Dependency-free (no ephemeris types) so the scheduler stays in Core.
struct PlannedTransitNotification: Equatable, Sendable {
    /// Stable per-event id (the scheduler adds its own prefix when registering).
    let id: String
    let title: String
    let body: String
    /// When to fire — calendar components in the user's local calendar (we
    /// deliver at a kind hour on the transit's day, never the exact minute).
    let fireDateComponents: DateComponents
}
