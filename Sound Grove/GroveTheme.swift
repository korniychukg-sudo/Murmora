import SwiftUI

/// Fixed dusk-luxe palette. Theme-independent (forced dark via preferredColorScheme).
enum Grove {
    // Surfaces
    static let bg       = Color(red: 0.055, green: 0.063, blue: 0.125)
    static let bgDeep   = Color(red: 0.027, green: 0.035, blue: 0.078)
    static let card     = Color.white.opacity(0.06)
    static let cardHi   = Color.white.opacity(0.10)
    static let stroke   = Color.white.opacity(0.10)
    static let ink      = Color(red: 0.933, green: 0.941, blue: 0.980)
    static let subtle   = Color(red: 0.60, green: 0.635, blue: 0.745)
    static let faint    = Color(red: 0.42, green: 0.45, blue: 0.56)

    // Accents
    static let primary  = Color(red: 0.70, green: 0.60, blue: 0.94)   // lavender
    static let primaryDeep = Color(red: 0.50, green: 0.42, blue: 0.80)
    static let gold     = Color(red: 0.98, green: 0.80, blue: 0.45)
    static let goldDeep = Color(red: 0.95, green: 0.62, blue: 0.30)

    // Category accents (match generated art)
    static func accent(_ c: SoundCat) -> Color {
        switch c {
        case .sky:    return Color(red: 0.53, green: 0.66, blue: 0.92)
        case .water:  return Color(red: 0.36, green: 0.78, blue: 0.80)
        case .fire:   return Color(red: 0.98, green: 0.68, blue: 0.34)
        case .forest: return Color(red: 0.52, green: 0.74, blue: 0.50)
        case .tones:  return Color(red: 0.70, green: 0.60, blue: 0.94)
        }
    }
    static func accentDeep(_ c: SoundCat) -> Color {
        switch c {
        case .sky:    return Color(red: 0.34, green: 0.46, blue: 0.78)
        case .water:  return Color(red: 0.20, green: 0.55, blue: 0.62)
        case .fire:   return Color(red: 0.93, green: 0.44, blue: 0.28)
        case .forest: return Color(red: 0.28, green: 0.52, blue: 0.40)
        case .tones:  return Color(red: 0.50, green: 0.42, blue: 0.80)
        }
    }

    static let bgGradient = LinearGradient(
        gradient: Gradient(colors: [bg, bgDeep]),
        startPoint: .top, endPoint: .bottom)

    static func gradient(_ c: SoundCat) -> LinearGradient {
        LinearGradient(gradient: Gradient(colors: [accent(c), accentDeep(c)]),
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let heroGradient = LinearGradient(
        gradient: Gradient(colors: [primary, primaryDeep]),
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // XP / level curve for "listening levels"
    static func level(minutes: Int) -> (level: Int, into: Int, span: Int) {
        var lvl = 1, need = 30, remain = minutes
        while remain >= need { remain -= need; lvl += 1; need = Int(Double(need) * 1.25) }
        return (lvl, remain, need)
    }
}

// MARK: - Card styling

struct GroveCard: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Grove.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.03)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.32), radius: 14, x: 0, y: 8)
            )
    }
}

extension View {
    func groveCard(padding: CGFloat = 16, radius: CGFloat = 22) -> some View {
        modifier(GroveCard(padding: padding, radius: radius))
    }
    func glow(_ color: Color, radius: CGFloat = 18, opacity: Double = 0.5) -> some View {
        shadow(color: color.opacity(opacity), radius: radius)
    }
}
