import Foundation
import UIKit

/// Client for the shared, no-key AI proxy (`apps-ai-proxy`). No secret is embedded —
/// abuse is bounded server-side by the proxy's own per-IP rate limiter.
///
/// Rulehive sends one rulebook-page photo per `/vision` call (the proxy only
/// forwards the *first* image in a request) and asks the model to transcribe the
/// visible text verbatim — this is OCR-style transcription, not summarization, so
/// a search for an exact phrase later still finds it. `SearchEngine` then does all
/// the actual matching/ranking client-side, on the cleaned transcription text.
final class AIProxyClient {

    enum APIError: LocalizedError {
        case badStatus(Int)
        case emptyResponse
        case network(Error)

        var errorDescription: String? {
            switch self {
            case .badStatus, .emptyResponse:
                return "The transcription service is briefly unavailable. Try again in a moment."
            case .network:
                return "Couldn't reach the transcription service. Check your connection and try again."
            }
        }
    }

    static let baseURL = URL(string: "https://apps-ai-proxy.s0533495227.workers.dev")!
    private static let maxImageDimension: CGFloat = 1600
    private static let jpegQuality: CGFloat = 0.6

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: Public

    /// Sends one rulebook-page photo to `/vision` and returns its cleaned
    /// transcription. Throws only for actual transport/HTTP failures — a
    /// response that comes back oddly formatted is still cleaned up and used
    /// rather than treated as an error, since any transcribed text is useful
    /// to search over.
    func transcribePage(imageJPEG rawJPEG: Data) async throws -> String {
        let jpeg = Self.preparedJPEG(from: rawJPEG)
        let content = try await sendVision(systemPrompt: Self.transcriptionSystemPrompt, userText: Self.transcriptionUserPrompt, imageJPEG: jpeg)
        return Self.cleanTranscription(content)
    }

    // MARK: Prompts

    private static let transcriptionUserPrompt = "Transcribe every word of visible text in this rulebook page photo."

    private static let transcriptionSystemPrompt = """
    You are an OCR transcription engine for tabletop board-game rulebooks. You are \
    shown one photograph of a single rulebook page or two-page spread. Transcribe \
    every piece of visible printed text on the page exactly as written, in reading \
    order (left column top-to-bottom, then right column if a two-page spread) — \
    headings, body paragraphs, bullet lists, table contents, and captions. Preserve \
    the words verbatim; do not summarize, correct, or omit anything you can read, \
    including partially obscured text (transcribe your best reading of it).

    Respond with ONLY the transcribed text, no markdown fences, no commentary, no \
    preamble like "Here is the transcription:".
    """

    // MARK: Transport

    private func sendVision(systemPrompt: String, userText: String, imageJPEG: Data) async throws -> String {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent("vision"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let dataURI = "data:image/jpeg;base64,\(imageJPEG.base64EncodedString())"
        let body = ChatRequest(messages: [
            .system(systemPrompt),
            .userWithImage(text: userText, imageDataURI: dataURI),
        ])
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> String {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw APIError.network(error)
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError.badStatus(status)
        }
        guard let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
              let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw APIError.emptyResponse
        }
        return content
    }

    // MARK: Parsing helpers

    /// Strips markdown code fences and leading/trailing chatter that a vision
    /// model sometimes adds even when told not to, so the stored, searchable
    /// text is just the transcription itself.
    static func cleanTranscription(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.hasPrefix("```") {
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            }
            if text.hasSuffix("```") {
                text = String(text.dropLast(3))
            }
        }

        let preambles = [
            "here is the transcription:",
            "here's the transcription:",
            "transcription:",
        ]
        for preamble in preambles {
            if text.lowercased().hasPrefix(preamble) {
                text = String(text.dropFirst(preamble.count))
                break
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Image prep

    static func preparedJPEG(from data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let longEdge = max(image.size.width, image.size.height)
        var output = image
        if longEdge > maxImageDimension, longEdge > 0 {
            let scale = maxImageDimension / longEdge
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            output = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        }
        return output.jpegData(compressionQuality: jpegQuality) ?? data
    }
}

// MARK: - Wire types (matches apps-ai-proxy's OpenAI-compatible chat-completions shape)

private struct ChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: Content

        static func system(_ text: String) -> Message { Message(role: "system", content: .text(text)) }
        static func userText(_ text: String) -> Message { Message(role: "user", content: .text(text)) }
        static func userWithImage(text: String, imageDataURI: String) -> Message {
            Message(role: "user", content: .parts([.text(text), .image(imageDataURI)]))
        }
    }

    enum Content: Encodable {
        case text(String)
        case parts([ContentPart])

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let string): try container.encode(string)
            case .parts(let parts): try container.encode(parts)
            }
        }
    }

    struct ContentPart: Encodable {
        let type: String
        var text: String?
        var imageURL: ImageURL?

        enum CodingKeys: String, CodingKey {
            case type, text
            case imageURL = "image_url"
        }

        static func text(_ text: String) -> ContentPart { ContentPart(type: "text", text: text, imageURL: nil) }
        static func image(_ dataURI: String) -> ContentPart {
            ContentPart(type: "image_url", text: nil, imageURL: ImageURL(url: dataURI))
        }
    }

    struct ImageURL: Encodable { let url: String }

    let messages: [Message]
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String? }
        let message: Message
    }
    let choices: [Choice]
}
