import Foundation
import OSLog
import SwiftData

/// Versioned SwiftData schema + migration plan.
///
/// Why this exists: the app previously used `.modelContainer(for:)`, the
/// convenience modifier, with no `VersionedSchema` and no
/// `SchemaMigrationPlan`. That modifier **traps** when the store cannot be
/// opened, so the first post-1.0 model change that isn't lightweight-
/// migratable would have killed the app on the launch screen with no
/// recovery path except delete-and-reinstall — taking every journal entry
/// with it. Both models carry `@Attribute(.unique)`, and adding or removing
/// a unique constraint is explicitly *not* lightweight-migratable.
///
/// v1.0's schema is the baseline that can never be changed without a
/// migration plan, so the plan has to ship *with* v1.0 — retrofitting it
/// later doesn't help the installs that already exist.
///
/// **Adding a field later:** define `LuminaSchemaV2` with the new model
/// shape, add it to `schemas`, and append a `MigrationStage` — `.lightweight`
/// if SwiftData can infer the change, `.custom` otherwise. Never edit V1.
enum LuminaSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [JournalEntry.self, Friend.self]
    }
}

enum LuminaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LuminaSchemaV1.self]
    }

    /// Empty at v1 — there is nothing to migrate *from* yet. Each future
    /// schema version appends exactly one stage here.
    static var stages: [MigrationStage] { [] }
}

/// Builds the app's `ModelContainer` without trapping.
///
/// `.modelContainer(for:)` calls `fatalError` on failure. A store that fails
/// to open is recoverable — the user keeps a working app and loses only the
/// local store — so this degrades instead of crashing, and records that it
/// degraded so the UI can be honest about it rather than silently pretending
/// the journal was always empty.
enum LuminaModelContainer {
    /// True when the on-disk store could not be opened and an in-memory
    /// store is standing in. Entries written in this state do not persist.
    private(set) nonisolated(unsafe) static var isEphemeralFallback = false

    /// Built once. `body` is re-evaluated constantly, so calling `make()`
    /// inline would try to reopen the store on every pass.
    static let shared: ModelContainer = make()

    static func make() -> ModelContainer {
        let schema = Schema(versionedSchema: LuminaSchemaV1.self)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: LuminaMigrationPlan.self,
                configurations: ModelConfiguration(schema: schema)
            )
        } catch {
            Logger(subsystem: "app.lumina.ios", category: "SwiftData").error(
                "Persistent store failed to open: \(error.localizedDescription, privacy: .public). Falling back to an in-memory store — this session's Reflect and People data will not be saved."
            )
        }

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: LuminaMigrationPlan.self,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
            isEphemeralFallback = true
            return container
        } catch {
            // An in-memory store failing means the schema itself is invalid,
            // which is a programmer error we cannot recover from at runtime.
            fatalError("In-memory SwiftData container failed to build: \(error)")
        }
    }
}
