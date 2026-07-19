import SwiftUI

/// Names a new game, then hands off to the page-capture flow. A real
/// tap-anywhere-to-dismiss-keyboard surface sits behind the form.
struct AddGameSheet: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @FocusState private var titleFocused: Bool
    @State private var createdGame: Game?
    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            ZStack {
                RulehiveColor.paper.ignoresSafeArea()
                    .dismissKeyboardOnTap()

                VStack(alignment: .leading, spacing: 18) {
                    Text("What's the game?")
                        .font(RulehiveFont.title(22))
                        .foregroundStyle(RulehiveColor.ink)

                    TextField("e.g. Wingspan, Catan, Root", text: $title)
                        .focused($titleFocused)
                        .font(RulehiveFont.body(17))
                        .padding(14)
                        .background(RulehiveColor.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RulehiveColor.hairline, lineWidth: 1))
                        .submitLabel(.done)
                        .onSubmit(startCapture)

                    Text("Next, you'll photograph each page or spread of its rulebook. Rulehive transcribes and indexes the text so you can search it mid-game.")
                        .font(.footnote)
                        .foregroundStyle(RulehiveColor.inkMuted)

                    Spacer()

                    Button("Start Photographing Pages") { startCapture() }
                        .bookButton(tint: RulehiveColor.cover)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .navigationDestination(isPresented: $showCapture) {
                if let createdGame {
                    PageCaptureFlowView(game: createdGame)
                }
            }
        }
    }

    private func startCapture() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        titleFocused = false
        createdGame = appModel.addGame(title: trimmed)
        showCapture = true
    }
}
