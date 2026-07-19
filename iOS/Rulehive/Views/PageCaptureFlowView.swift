import SwiftUI

/// Repeated "photograph a page → OCR it → append to the index" loop. Each photo is
/// one `/vision` call; the cleaned transcription plus a thumbnail become one
/// `PageRecord` on the game.
struct PageCaptureFlowView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let game: Game

    @State private var showCamera = false
    @State private var isTranscribing = false
    @State private var errorMessage: String?
    @State private var pages: [PageRecord] = []

    private let client = AIProxyClient()

    var body: some View {
        ZStack {
            RulehiveColor.paper.ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 36))
                        .foregroundStyle(RulehiveColor.cover)
                    Text("\(pages.count) page\(pages.count == 1 ? "" : "s") indexed")
                        .font(RulehiveFont.headline(17))
                        .foregroundStyle(RulehiveColor.ink)
                    Text("Photograph the next page or two-page spread of \(game.title)'s rulebook.")
                        .font(.footnote)
                        .foregroundStyle(RulehiveColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 24)

                if !pages.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
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
                        .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 0)

                if isTranscribing {
                    ProgressView("Transcribing page…")
                        .tint(RulehiveColor.gold)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        showCamera = true
                    } label: {
                        Label("Photograph a Page", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .bookButton(tint: RulehiveColor.cover)
                    .disabled(isTranscribing)

                    Button("Done Adding Pages") { dismiss() }
                        .bookButton(filled: false, tint: RulehiveColor.gold)
                        .disabled(pages.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isTranscribing)
        .fullScreenCover(isPresented: $showCamera) {
            PageCaptureSheet(pageNumber: pages.count + 1) { jpeg in
                Task { await transcribe(jpeg: jpeg) }
            }
        }
        .onAppear { pages = game.pages }
    }

    private func transcribe(jpeg: Data) async {
        isTranscribing = true
        errorMessage = nil
        defer { isTranscribing = false }
        do {
            let text = try await client.transcribePage(imageJPEG: jpeg)
            let thumbnail = AIProxyClient.preparedJPEG(from: jpeg)
            let record = PageRecord(pageLabel: "Page \(pages.count + 1)", extractedText: text, thumbnailJPEG: thumbnail)
            appModel.appendPage(record, to: game)
            pages = game.pages
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.warning()
        }
    }
}
