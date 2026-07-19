import SwiftUI

/// Rulebook-cover identity: warm parchment + a deep maroon "cover" surface, one
/// vivid gold-foil accent reserved for the search/AI hook and the Pro call-to-action.
/// Shape language is soft "hardback book" — rounded card corners with a spine-accent
/// bar down the left edge — the opposite of a sharp/technical template.
enum RulehiveColor {
    static let paper = Color(light: Color(hex: 0xF5E9D3), dark: Color(hex: 0x1C1712))
    static let panel = Color(light: Color(hex: 0xEFE0BE), dark: Color(hex: 0x2A2119))
    static let ink = Color(light: Color(hex: 0x2B211A), dark: Color(hex: 0xEFE0C8))
    static let inkMuted = Color(light: Color(hex: 0x7A6A52), dark: Color(hex: 0x9C8B6E))
    static let hairline = Color(light: Color(hex: 0xD9C79E), dark: Color(hex: 0x40331F))

    /// Deep rulebook-cover maroon — used for the book-spine accent and secondary chrome.
    static let cover = Color(hex: 0x7A2331)
    static let coverDim = Color(hex: 0x7A2331).opacity(0.35)

    /// The single vivid accent. Reserved for the search/page-flip hook, matched
    /// pages, and the Pro call-to-action — never ordinary chrome.
    static let gold = Color(hex: 0xC9A227)
    static let goldDim = Color(hex: 0xC9A227).opacity(0.35)
}

enum RulehiveFont {
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .serif) }
    static func headline(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func pageLabel(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .bold, design: .monospaced) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular) }
    static func caption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .semibold) }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

/// A rounded "hardback book" card with a spine-accent bar down the left edge —
/// the primary chrome container across Rulehive.
struct BookPanel<Content: View>: View {
    var accent: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accent ? RulehiveColor.gold : RulehiveColor.cover)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 12) { content }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(RulehiveColor.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(RulehiveColor.hairline, lineWidth: 1)
        )
    }
}

/// Uppercase tracked label, styled like foil-stamped text on a spine.
struct SpineLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(RulehiveFont.caption())
            .tracking(1.6)
            .foregroundStyle(RulehiveColor.inkMuted)
    }
}

/// Primary CTA — rounded solid bar. Gold only for search/AI-related actions;
/// cover maroon otherwise.
struct BookButtonStyle: ButtonStyle {
    var filled: Bool = true
    var tint: Color = RulehiveColor.cover

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RulehiveFont.headline())
            .foregroundStyle(filled ? Color.white : tint)
            .padding(.vertical, 13)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(filled ? tint : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tint, lineWidth: filled ? 0 : 1.4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    func bookButton(filled: Bool = true, tint: Color = RulehiveColor.cover) -> some View {
        buttonStyle(BookButtonStyle(filled: filled, tint: tint))
    }

    /// Real tap-anywhere-to-dismiss-keyboard behavior for any text-entry screen.
    /// A transparent tap surface behind the content resigns first responder.
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

/// A small dog-ear corner fold, used to bracket page thumbnails — echoes the
/// "physical book page" language at rest.
struct DogEarCorner: Shape {
    var length: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        path.closeSubpath()
        return path
    }
}
