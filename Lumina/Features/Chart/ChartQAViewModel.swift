import Foundation

/// Drives the free-text "Ask your chart" flow: builds grounded facts, calls the
/// server-side LLM, and exposes load state. The curated `ChartOracle` answers
/// stay the always-available fallback (they need no key), so this only ever
/// adds capability, never gates the existing experience.
@MainActor
@Observable
final class ChartQAViewModel {
    enum AskState: Equatable {
        case idle
        case loading
        case answer(String)
        case failed(LuminaError)
    }

    private let client: LuminaAIClient
    private(set) var state: AskState = .idle

    init(client: LuminaAIClient = LuminaAIClient()) {
        self.client = client
    }

    /// Show the free-text box only when the app is wired to a backend. If the
    /// *server* lacks an Anthropic key, that surfaces as a gentle inline note
    /// when the user actually asks — not by hiding the entry point.
    var offersConversation: Bool {
        client.isConfigured
    }

    var isLoading: Bool {
        state == .loading
    }

    func ask(_ question: String, chart: NatalChart) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state = .loading
        do {
            let text = try await client.ask(trimmed, chart: chart)
            state = .answer(text)
            Haptics.success.play()
        } catch {
            state = .failed(LuminaError.from(error))
            Haptics.failure.play()
        }
    }
}
