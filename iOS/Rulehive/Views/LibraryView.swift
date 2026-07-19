import SwiftUI

/// The game library: every indexed rulebook, tap through to search or add pages.
/// Free tier caps the library at `AppModel.freeGameLimit` games.
struct LibraryView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showAddGame = false
    @State private var showPaywall = false

    private var summaries: [GameSummary] {
        appModel.games().map(GameSummary.init)
    }

    var body: some View {
        ZStack {
            RulehiveColor.paper.ignoresSafeArea()

            if summaries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(summaries) { summary in
                            NavigationLink {
                                if let game = appModel.games().first(where: { $0.id == summary.id }) {
                                    GameDetailView(game: game)
                                }
                            } label: {
                                GameRow(game: summary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            addGameButton
        }
        .sheet(isPresented: $showAddGame) { AddGameSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 44))
                .foregroundStyle(RulehiveColor.cover)
            Text("No games indexed yet")
                .font(RulehiveFont.title(20))
                .foregroundStyle(RulehiveColor.ink)
            Text("Photograph your rulebook's pages once — then search them by typing a question mid-game.")
                .font(.subheadline)
                .foregroundStyle(RulehiveColor.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addGameButton: some View {
        VStack(spacing: 6) {
            Button {
                Haptics.tap()
                if appModel.canAddAnotherGame {
                    showAddGame = true
                } else {
                    showPaywall = true
                }
            } label: {
                Label("Add a Game", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .bookButton(tint: RulehiveColor.cover)

            if !store.isPro {
                Text("\(summaries.count) of \(AppModel.freeGameLimit) free games indexed")
                    .font(.caption)
                    .foregroundStyle(RulehiveColor.inkMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}
