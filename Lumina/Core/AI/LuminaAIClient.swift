import Foundation
import OSLog

/// Client for Lumina's interpretive content. Interpretation is RAG-grounded
/// and runs **server-side**: the app POSTs to the Lumina backend, which holds
/// the Anthropic key and the RAG corpus. The Anthropic key is deliberately
/// NOT shipped in the app bundle — a client-side key is trivially extractable
/// from the IPA. See docs/AUDIT-2026-06-03.md R2.
actor LuminaAIClient {
    enum ClientError: Error {
        case notImplemented
        case missingAPIKey
        case invalidResponse
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "AI")
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func dailyReading(transitSummary: String) async throws -> String {
        // TODO(lumina): POST transitSummary to the backend daily-reading
        // endpoint with the X-Lumina-Secret header; the backend performs RAG
        // retrieval and the Anthropic call.
        logger.debug("dailyReading requested")
        throw ClientError.notImplemented
    }
}
