import Foundation
import SwiftData

/// One indexed rulebook page: the label the user gave it (or an auto-numbered
/// default), the OCR-transcribed text, and a downsized JPEG thumbnail of the photo.
struct PageRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var pageLabel: String
    var extractedText: String
    var thumbnailJPEG: Data
    var createdAt: Date = Date()
}

/// A board game whose rulebook pages have been photographed and indexed.
/// Pages are stored as an encoded array (mirrors the simple embedded-JSON pattern
/// used across this app factory) rather than a SwiftData relationship, since a
/// game's whole page set is always read/written together.
@Model
final class Game {
    var id: UUID
    var title: String
    var createdAt: Date
    var pagesJSON: Data

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), pages: [PageRecord] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.pagesJSON = (try? JSONEncoder().encode(pages)) ?? Data()
    }

    var pages: [PageRecord] {
        get { (try? JSONDecoder().decode([PageRecord].self, from: pagesJSON)) ?? [] }
        set { pagesJSON = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    func appendPage(_ page: PageRecord) {
        var current = pages
        current.append(page)
        pages = current
    }

    func removePage(id: UUID) {
        pages = pages.filter { $0.id != id }
    }
}

/// Lightweight, `Sendable`-friendly projection of a `Game` for the library list.
struct GameSummary: Identifiable, Equatable {
    let id: UUID
    let title: String
    let createdAt: Date
    let pageCount: Int

    init(game: Game) {
        id = game.id
        title = game.title
        createdAt = game.createdAt
        pageCount = game.pages.count
    }
}

/// Pure projection of one indexed page used by `SearchEngine` — no SwiftData,
/// no networking, so search/ranking logic is trivially unit-testable.
struct IndexedPage: Equatable {
    let id: UUID
    let pageLabel: String
    let text: String

    init(id: UUID = UUID(), pageLabel: String, text: String) {
        self.id = id
        self.pageLabel = pageLabel
        self.text = text
    }
}

/// One ranked search result: which page it came from, a short snippet of the
/// matched text, and the relevance score it was ranked by.
struct SearchHit: Identifiable, Hashable {
    let id: UUID
    let pageLabel: String
    let snippet: String
    let score: Int
    let fullText: String
}
