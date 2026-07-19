import Foundation

/// Pure, client-side keyword/substring relevance search over a game's indexed
/// pages — no network, no persistence. Deliberately simple rather than fancy:
/// mid-game you want "does this contain the words I typed", ranked, not a
/// semantic search stack.
enum SearchEngine {

    private static let snippetRadius = 60

    /// Ranks every page against `query`, returning only pages that matched at
    /// least one query token, best match first. Ties break by page order in
    /// `pages` (stable sort), so results are deterministic.
    static func search(query: String, in pages: [IndexedPage]) -> [SearchHit] {
        let tokens = tokenize(query)
        guard !tokens.isEmpty else { return [] }

        var scored: [(index: Int, score: Int, page: IndexedPage)] = []
        for (index, page) in pages.enumerated() {
            let score = relevanceScore(tokens: tokens, phrase: query, text: page.text)
            if score > 0 {
                scored.append((index, score, page))
            }
        }

        let ranked = scored.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.index < rhs.index
        }

        return ranked.map { entry in
            SearchHit(
                id: entry.page.id,
                pageLabel: entry.page.pageLabel,
                snippet: snippet(for: tokens, in: entry.page.text),
                score: entry.score,
                fullText: entry.page.text
            )
        }
    }

    /// Score for one page: sum of per-token occurrence counts (case-insensitive
    /// substring match, so partial words like "trad" still find "trading"),
    /// plus a flat bonus if the entire typed phrase appears verbatim anywhere
    /// in the text — the strongest possible signal for a direct rules lookup.
    static func relevanceScore(tokens: [String], phrase: String, text: String) -> Int {
        let lowerText = text.lowercased()
        var score = 0
        for token in tokens {
            score += occurrenceCount(of: token, in: lowerText)
        }
        // Only a genuine multi-word phrase counts as the strong "exact phrase" signal —
        // a single-word query already gets full credit from the per-token count above.
        let trimmedPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if tokens.count > 1, trimmedPhrase.count > 1, lowerText.contains(trimmedPhrase) {
            score += 10
        }
        return score
    }

    /// Lowercased, punctuation-stripped query words, shortest-first filtered
    /// (empty pieces dropped). Single-letter tokens are kept — a rules lookup
    /// like "d6" or "1d20" should still count all its characters.
    static func tokenize(_ query: String) -> [String] {
        query
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private static func occurrenceCount(of token: String, in lowerText: String) -> Int {
        guard !token.isEmpty else { return 0 }
        var count = 0
        var searchRange = lowerText.startIndex..<lowerText.endIndex
        while let range = lowerText.range(of: token, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<lowerText.endIndex
        }
        return count
    }

    /// A short excerpt centered on the first matched token, so the result
    /// preview shows *why* the page matched rather than just its opening line.
    static func snippet(for tokens: [String], in text: String) -> String {
        let lowerText = text.lowercased()
        var firstMatchRange: Range<String.Index>?
        for token in tokens {
            if let range = lowerText.range(of: token) {
                if firstMatchRange == nil || range.lowerBound < firstMatchRange!.lowerBound {
                    firstMatchRange = range
                }
            }
        }
        guard let matchRange = firstMatchRange else {
            return String(text.prefix(120))
        }

        let start = lowerText.index(matchRange.lowerBound, offsetBy: -snippetRadius, limitedBy: lowerText.startIndex) ?? lowerText.startIndex
        let end = lowerText.index(matchRange.upperBound, offsetBy: snippetRadius, limitedBy: lowerText.endIndex) ?? lowerText.endIndex

        let startOffset = lowerText.distance(from: lowerText.startIndex, to: start)
        let endOffset = lowerText.distance(from: lowerText.startIndex, to: end)
        let textStart = text.index(text.startIndex, offsetBy: startOffset)
        let textEnd = text.index(text.startIndex, offsetBy: endOffset)

        var excerpt = String(text[textStart..<textEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        if start != lowerText.startIndex { excerpt = "…" + excerpt }
        if end != lowerText.endIndex { excerpt += "…" }
        return excerpt
    }
}
