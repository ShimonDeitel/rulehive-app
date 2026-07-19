import SwiftUI

/// One game's indexed pages, plus entry points to search them or add more.
struct GameDetailView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let game: Game

    @State private var showAddPages = false
    @State private var showDeleteConfirm = false

    private var pages: [PageRecord] { game.pages }

    var body: some View {
        ZStack {
            RulehiveColor.paper.ignoresSafeArea()

            if pages.isEmpty {
                Text("No pages indexed yet.")
                    .font(.subheadline)
                    .foregroundStyle(RulehiveColor.inkMuted)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(pages) { page in
                            BookPanel {
                                SpineLabel(text: page.pageLabel)
                                Text(page.extractedText)
                                    .font(.footnote)
                                    .foregroundStyle(RulehiveColor.ink)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                NavigationLink {
                    SearchView(game: game)
                } label: {
                    Label("Search Rules", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .bookButton(tint: RulehiveColor.gold)
                .disabled(pages.isEmpty)

                Button {
                    Haptics.tap()
                    showAddPages = true
                } label: {
                    Image(systemName: "camera.fill")
                        .frame(width: 44, height: 44)
                }
                .bookButton(filled: false, tint: RulehiveColor.cover)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete Game")
            }
        }
        .navigationDestination(isPresented: $showAddPages) {
            PageCaptureFlowView(game: game)
        }
        .alert("Delete \(game.title)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                appModel.deleteGame(game)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all indexed pages for this game.")
        }
    }
}
