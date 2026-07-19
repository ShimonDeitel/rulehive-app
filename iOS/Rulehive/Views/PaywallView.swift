import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var working = false
    @State private var restoreMessage: String?

    private let benefits: [(String, String, String)] = [
        ("infinity", "Unlimited games", "Index every rulebook on your shelf, not just \(AppModel.freeGameLimit)."),
        ("magnifyingglass", "Search across all of them", "Type a question and jump straight to the page that answers it, in any indexed game."),
        ("camera.fill", "No page limit per game", "Photograph as many spreads as a rulebook needs — sprawling campaign rulebooks included."),
    ]

    var body: some View {
        ZStack {
            RulehiveColor.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(RulehiveColor.gold)
                        Text("Rulehive Pro").font(RulehiveFont.title(28))
                            .foregroundStyle(RulehiveColor.ink)
                        Text("\(store.displayPrice) / month. Cancel anytime.")
                            .font(.subheadline).foregroundStyle(RulehiveColor.inkMuted)
                    }
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(benefits, id: \.0) { item in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: item.0)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(RulehiveColor.gold)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.1).font(RulehiveFont.headline(16))
                                        .foregroundStyle(RulehiveColor.ink)
                                    Text(item.2).font(.subheadline).foregroundStyle(RulehiveColor.inkMuted)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(16)
                    .background(RulehiveColor.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(RulehiveColor.hairline, lineWidth: 1))
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        Button {
                            Task { await buy() }
                        } label: {
                            HStack {
                                if working { ProgressView().tint(.white) }
                                Text(working ? "Starting…" : "Start Rulehive Pro · \(store.displayPrice)/mo")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .bookButton(tint: RulehiveColor.gold)
                        .accessibilityIdentifier("paywall-subscribe")
                        .disabled(working)

                        Button("Restore Purchase") { Task { await restore() } }
                            .font(.subheadline).tint(RulehiveColor.inkMuted)

                        if let restoreMessage {
                            Text(restoreMessage).font(.footnote).foregroundStyle(RulehiveColor.inkMuted)
                        }

                        Text("Auto-renewable subscription, billed monthly to your Apple ID. Manage or cancel anytime in Settings.")
                            .font(.footnote).foregroundStyle(RulehiveColor.inkMuted)
                            .multilineTextAlignment(.center).padding(.top, 4)
                    }
                    .padding(.horizontal).padding(.bottom, 30)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.title2)
                    .foregroundStyle(RulehiveColor.inkMuted).padding()
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("paywall-close")
        }
        .onChange(of: store.isPro) { _, newValue in if newValue { dismiss() } }
    }

    private func buy() async {
        working = true
        let ok = await store.purchase()
        working = false
        if ok { Haptics.success(); dismiss() }
    }

    private func restore() async {
        await store.restore()
        if store.isPro { Haptics.success(); dismiss() }
        else { restoreMessage = "No previous purchase found on this Apple ID." }
    }
}
