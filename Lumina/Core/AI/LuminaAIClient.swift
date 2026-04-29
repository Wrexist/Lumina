import Foundation
import OSLog

/// Wraps the Anthropic Messages API. All interpretive content is RAG-grounded —
/// retrieval lives in `RAGRetriever`, which is composed in by callers.
actor LuminaAIClient {
    enum ClientError: Error {
        case notImplemented
        case missingAPIKey
        case invalidResponse
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "AI")
    private let session: URLSession
    private let apiKey: String?

    init(session: URLSession = .shared, infoPlist: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        self.session = session
        self.apiKey = infoPlist["LuminaAnthropicAPIKey"] as? String
    }

    func dailyReading(transitSummary: String) async throws -> String {
        // TODO(lumina): call Anthropic Messages API with RAG-augmented system prompt.
        logger.debug("dailyReading requested")
        throw ClientError.notImplemented
    }
}
