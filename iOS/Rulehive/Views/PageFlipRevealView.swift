import SwiftUI

/// The signature "thumb through pages" animation: a fan of page-edge cards riffles
/// left-to-right, staggered per card, then springs to a stop on the matched page,
/// which pops forward and highlights gold. Purely decorative/state-driven — no
/// business logic lives here, so it isn't unit-tested, only the ranking that
/// decides which page is "the match" is.
struct PageFlipRevealView: View {
    /// How many page-edge cards to draw in the riffle fan (capped for readability).
    let cardCount: Int
    /// Index (within the drawn fan) that should end up highlighted, or nil while
    /// no result is settled yet.
    let matchedIndex: Int?
    /// Bump this to replay the riffle (e.g. once per new search).
    let trigger: Int

    @State private var settled = false

    private var visibleCount: Int { min(max(cardCount, 1), 9) }

    var body: some View {
        HStack(spacing: -18) {
            ForEach(0..<visibleCount, id: \.self) { index in
                card(at: index)
        }
        }
        .frame(height: 92)
        .frame(maxWidth: .infinity)
        .onAppear { animate() }
        .onChange(of: trigger) { _, _ in animate() }
    }

    private func card(at index: Int) -> some View {
        let isMatch = matchedIndex == index
        let delay = Double(index) * 0.045

        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isMatch && settled ? RulehiveColor.gold.opacity(0.22) : RulehiveColor.panel)
            .frame(width: 30, height: isMatch && settled ? 92 : 70)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isMatch && settled ? RulehiveColor.gold : RulehiveColor.hairline, lineWidth: isMatch && settled ? 2 : 1)
            )
            .rotation3DEffect(
                .degrees(settled ? (isMatch ? 0 : 8) : 55),
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.6
            )
            .offset(y: settled ? (isMatch ? -8 : 0) : 24)
            .zIndex(isMatch ? 1 : 0)
            .animation(.interpolatingSpring(stiffness: 170, damping: 14).delay(delay), value: settled)
    }

    private func animate() {
        settled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            settled = true
        }
    }
}
