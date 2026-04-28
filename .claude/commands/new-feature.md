Scaffold a new Lumina feature module. 

Usage: /new-feature <FeatureName>
Example: /new-feature DailyReading

Creates the following structure under `Features/<FeatureName>/`:
- `<FeatureName>View.swift` — root SwiftUI view
- `<FeatureName>ViewModel.swift` — `@MainActor @Observable final class`
- `<FeatureName>Router.swift` — navigation path management (if multi-screen)

**ViewModel template:**
```swift
// <FeatureName>ViewModel.swift
import SwiftUI

@MainActor
@Observable
final class <FeatureName>ViewModel {
    // MARK: - State
    private(set) var isLoading = false
    private(set) var error: <FeatureName>Error?

    // MARK: - Dependencies (injected, never singletons in views)
    private let ephemerisService: EphemerisService
    private let aiClient: LuminaAIClient

    init(ephemerisService: EphemerisService, aiClient: LuminaAIClient) {
        self.ephemerisService = ephemerisService
        self.aiClient = aiClient
    }
}

enum <FeatureName>Error: LocalizedError {
    case fetchFailed(underlying: Error)
}
```

After scaffolding, add tasks to TASK.md under the appropriate feature section.
