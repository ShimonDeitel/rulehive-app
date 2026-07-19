import SwiftUI
import UIKit

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func click() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

/// A row for one game in the library list.
struct GameRow: View {
    let game: GameSummary

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(RulehiveColor.cover)
                .frame(width: 40, height: 52)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(RulehiveColor.gold)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(game.title)
                    .font(RulehiveFont.headline(16))
                    .foregroundStyle(RulehiveColor.ink)
                Text("\(game.pageCount) page\(game.pageCount == 1 ? "" : "s") indexed")
                    .font(.footnote)
                    .foregroundStyle(RulehiveColor.inkMuted)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RulehiveColor.inkMuted)
        }
        .padding(12)
        .background(RulehiveColor.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RulehiveColor.hairline, lineWidth: 1))
    }
}

/// A single search-result row: the matched page's label, a text snippet, and its
/// relevance score, tappable to open the full extracted-text detail.
struct SearchHitRow: View {
    let hit: SearchHit

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(hit.pageLabel)
                .font(RulehiveFont.pageLabel())
                .foregroundStyle(RulehiveColor.gold)
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(hit.snippet)
                    .font(RulehiveFont.body())
                    .foregroundStyle(RulehiveColor.ink)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(RulehiveColor.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(RulehiveColor.hairline, lineWidth: 1))
    }
}

/// A locked Pro feature row — tapping when not subscribed opens the paywall.
struct ProToolRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(locked ? RulehiveColor.inkMuted : RulehiveColor.gold)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(RulehiveFont.headline(15)).foregroundStyle(RulehiveColor.ink)
                    Text(subtitle).font(.footnote).foregroundStyle(RulehiveColor.inkMuted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RulehiveColor.inkMuted)
            }
            .padding(14)
            .background(RulehiveColor.panel)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(RulehiveColor.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
