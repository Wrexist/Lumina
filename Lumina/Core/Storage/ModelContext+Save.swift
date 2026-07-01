import Foundation
import OSLog
import SwiftData

extension ModelContext {
    /// Saves pending changes, logging (rather than silently swallowing) any
    /// failure. A swallowed `try? save()` is dangerous here: the UI flips to a
    /// "Saved" state from the in-memory mutation even when the write never
    /// reached disk, masking real data loss. SwiftData save failures are rare
    /// but real (disk full, migration mismatch) — surface them at least to the
    /// log so they're diagnosable.
    func saveOrLog(category: String = "SwiftData") {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            Logger(subsystem: "app.lumina.ios", category: category)
                .error("model save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
