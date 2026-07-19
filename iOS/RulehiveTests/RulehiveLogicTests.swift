import XCTest
@testable import Rulehive

final class RulehiveLogicTests: XCTestCase {

    // MARK: Fixtures

    private let fixturePages: [IndexedPage] = [
        IndexedPage(pageLabel: "Page 1", text: "Setup: Each player takes 5 resource cards and places their pieces on the starting hexes."),
        IndexedPage(pageLabel: "Page 2", text: "Trading: On your turn, you may trade resource cards with other players before rolling. You cannot trade during setup."),
        IndexedPage(pageLabel: "Page 3", text: "Building: Spend resources to build roads, settlements, and cities. Roads connect to your existing network."),
        IndexedPage(pageLabel: "Page 4", text: "Winning: The first player to reach 10 victory points on their turn wins the game immediately."),
    ]

    // MARK: SearchEngine — tokenize

    func testTokenize_LowercasesAndStripsPunctuation() {
        XCTAssertEqual(SearchEngine.tokenize("Can you trade during setup?"), ["can", "you", "trade", "during", "setup"])
    }

    func testTokenize_EmptyQueryProducesNoTokens() {
        XCTAssertEqual(SearchEngine.tokenize("   "), [])
    }

    // MARK: SearchEngine — relevanceScore

    func testRelevanceScore_CountsSubstringOccurrencesPerToken() {
        let score = SearchEngine.relevanceScore(tokens: ["trade"], phrase: "trade", text: "You may trade now. Let's trade again later.")
        XCTAssertEqual(score, 2)
    }

    func testRelevanceScore_ExactPhraseBonus() {
        let withPhrase = SearchEngine.relevanceScore(tokens: ["trade", "during", "setup"], phrase: "trade during setup", text: fixturePages[1].text)
        let withoutPhrase = SearchEngine.relevanceScore(tokens: ["trade", "during", "setup"], phrase: "trade during setup", text: "trade elsewhere, setup elsewhere too, during nothing")
        XCTAssertGreaterThan(withPhrase, withoutPhrase)
    }

    // MARK: SearchEngine — search / ranking

    func testSearch_ReturnsMatchingPageRankedFirst() {
        let hits = SearchEngine.search(query: "can you trade during setup", in: fixturePages)
        XCTAssertFalse(hits.isEmpty)
        XCTAssertEqual(hits.first?.pageLabel, "Page 2")
    }

    func testSearch_NoMatchesReturnsEmpty() {
        let hits = SearchEngine.search(query: "spaceship laser cannon", in: fixturePages)
        XCTAssertTrue(hits.isEmpty)
    }

    func testSearch_EmptyQueryReturnsEmpty() {
        XCTAssertTrue(SearchEngine.search(query: "", in: fixturePages).isEmpty)
        XCTAssertTrue(SearchEngine.search(query: "   ", in: fixturePages).isEmpty)
    }

    func testSearch_TieBreaksByOriginalPageOrder() {
        let pages = [
            IndexedPage(pageLabel: "Page A", text: "resource resource"),
            IndexedPage(pageLabel: "Page B", text: "resource resource"),
        ]
        let hits = SearchEngine.search(query: "resource", in: pages)
        XCTAssertEqual(hits.map(\.pageLabel), ["Page A", "Page B"])
    }

    func testSearch_RanksMultipleTokenHitsAboveSingleTokenHits() {
        let pages = [
            IndexedPage(pageLabel: "Page 1", text: "Only victory matters here."),
            IndexedPage(pageLabel: "Page 2", text: "Victory points win the game. Points and win conditions matter for victory."),
        ]
        let hits = SearchEngine.search(query: "victory points win", in: pages)
        XCTAssertEqual(hits.first?.pageLabel, "Page 2")
    }

    // MARK: SearchEngine — snippet

    func testSnippet_ContainsMatchedTokenWithSurroundingContext() {
        let snippet = SearchEngine.snippet(for: ["trade"], in: fixturePages[1].text)
        XCTAssertTrue(snippet.localizedCaseInsensitiveContains("trade"))
    }

    func testSnippet_TruncatesLongTextWithEllipsis() {
        let longText = String(repeating: "filler words here. ", count: 20) + "the secret trade phrase" + String(repeating: " more filler text.", count: 20)
        let snippet = SearchEngine.snippet(for: ["trade"], in: longText)
        XCTAssertTrue(snippet.hasPrefix("…"))
        XCTAssertTrue(snippet.hasSuffix("…"))
    }

    // MARK: AppModel — free tier gate (pure logic, no SwiftData/StoreKit needed)

    func testCanAddGame_FreeTierBlockedAtLimit() {
        XCTAssertTrue(AppModel.canAddGame(existingCount: 0, isPro: false))
        XCTAssertTrue(AppModel.canAddGame(existingCount: AppModel.freeGameLimit - 1, isPro: false))
        XCTAssertFalse(AppModel.canAddGame(existingCount: AppModel.freeGameLimit, isPro: false))
    }

    func testCanAddGame_ProNeverBlocked() {
        XCTAssertTrue(AppModel.canAddGame(existingCount: AppModel.freeGameLimit, isPro: true))
        XCTAssertTrue(AppModel.canAddGame(existingCount: 999, isPro: true))
    }

    // MARK: AIProxyClient — response cleanup (mocked strings, no network)

    func testCleanTranscription_StripsMarkdownFence() {
        let raw = "```\nSetup: Each player takes 5 resource cards.\n```"
        XCTAssertEqual(AIProxyClient.cleanTranscription(raw), "Setup: Each player takes 5 resource cards.")
    }

    func testCleanTranscription_StripsLeadingPreamble() {
        let raw = "Here is the transcription:\nTrading: On your turn, you may trade."
        XCTAssertEqual(AIProxyClient.cleanTranscription(raw), "Trading: On your turn, you may trade.")
    }

    func testCleanTranscription_PassesThroughPlainTextUnchanged() {
        let raw = "Winning: The first player to reach 10 victory points wins."
        XCTAssertEqual(AIProxyClient.cleanTranscription(raw), raw)
    }

    func testCleanTranscription_TrimsWhitespace() {
        let raw = "  \n  Setup rules go here.  \n\n "
        XCTAssertEqual(AIProxyClient.cleanTranscription(raw), "Setup rules go here.")
    }

    // MARK: PageRecord round-trip through Game (Codable storage, no SwiftData context needed)

    func testGame_AppendPageRoundTripsThroughJSONStorage() {
        let game = Game(title: "Wingspan")
        XCTAssertEqual(game.pages.count, 0)

        let page = PageRecord(pageLabel: "Page 1", extractedText: "Setup text", thumbnailJPEG: Data([0x01, 0x02]))
        game.appendPage(page)

        XCTAssertEqual(game.pages.count, 1)
        XCTAssertEqual(game.pages[0].pageLabel, "Page 1")
        XCTAssertEqual(game.pages[0].extractedText, "Setup text")
    }

    func testGame_RemovePageByID() {
        let game = Game(title: "Root")
        let page1 = PageRecord(pageLabel: "Page 1", extractedText: "a", thumbnailJPEG: Data())
        let page2 = PageRecord(pageLabel: "Page 2", extractedText: "b", thumbnailJPEG: Data())
        game.appendPage(page1)
        game.appendPage(page2)

        game.removePage(id: page1.id)

        XCTAssertEqual(game.pages.count, 1)
        XCTAssertEqual(game.pages[0].id, page2.id)
    }
}
