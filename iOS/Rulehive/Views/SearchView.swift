import SwiftUI

/// Type a question ("can you trade during setup") and search across every page
/// indexed for this game. Free tier already restricted which games could be
/// added; search itself works the same for free and Pro on the current game —
/// Pro's benefit is being able to have more than `AppModel.freeGameLimit` games
/// each with their own searchable index (see `SettingsView`/`PaywallView`).
struct SearchView: View {
    let game: Game

    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var hits: [SearchHit] = []
    @State private var searchTrigger = 0
    @State private var selectedHit: SearchHit?

    private var indexedPages: [IndexedPage] {
        game.pages.map { IndexedPage(id: $0.id, pageLabel: $0.pageLabel, text: $0.extractedText) }
    }

    var body: some View {
        ZStack {
            RulehiveColor.paper.ignoresSafeArea()
                .dismissKeyboardOnTap()

            VStack(spacing: 14) {
                searchField

                if !hits.isEmpty {
                    PageFlipRevealView(cardCount: game.pages.count, matchedIndex: 0, trigger: searchTrigger)
                        .padding(.top, 4)
                }

                if query.isEmpty {
                    Spacer()
                    Text("Type a question about \(game.title)'s rules.")
                        .font(.subheadline)
                        .foregroundStyle(RulehiveColor.inkMuted)
                    Spacer()
                } else if hits.isEmpty {
                    Spacer()
                    Text("No indexed page mentions that.")
                        .font(.subheadline)
                        .foregroundStyle(RulehiveColor.inkMuted)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(hits) { hit in
                                Button {
                                    Haptics.tap()
                                    selectedHit = hit
                                } label: {
                                    SearchHitRow(hit: hit)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 12)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedHit) { hit in
            SearchResultDetailView(hit: hit, gameTitle: game.title)
        }
        .onChange(of: query) { _, newValue in runSearch(newValue) }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(RulehiveColor.inkMuted)
            TextField("e.g. can you trade during setup", text: $query)
                .focused($searchFocused)
                .font(RulehiveFont.body(16))
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                    hits = []
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(RulehiveColor.inkMuted)
                }
            }
        }
        .padding(12)
        .background(RulehiveColor.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RulehiveColor.hairline, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func runSearch(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            hits = []
            return
        }
        hits = SearchEngine.search(query: text, in: indexedPages)
        searchTrigger += 1
    }
}

/// Full extracted text of one matched page, with its label and a small settled
/// page-flip flourish on entry.
struct SearchResultDetailView: View {
    let hit: SearchHit
    let gameTitle: String

    var body: some View {
        ZStack {
            RulehiveColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PageFlipRevealView(cardCount: 1, matchedIndex: 0, trigger: 0)

                    BookPanel(accent: true) {
                        SpineLabel(text: hit.pageLabel)
                        Text(hit.fullText)
                            .font(RulehiveFont.body(16))
                            .foregroundStyle(RulehiveColor.ink)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(gameTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
