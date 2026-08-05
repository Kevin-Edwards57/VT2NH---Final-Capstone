//
//  Theme.swift
//  VT2NH
//
//  One place for color and shape decisions so the app reads as a single
//  product. Every color resolves through the system palette, which means dark
//  mode and increased-contrast work without a second set of definitions.
//

import SwiftUI

enum Theme {

    /// Green for Vermont, a deeper blue-green for New Hampshire. Used on
    /// state badges and the map legend.
    static func tint(for state: USState) -> Color {
        switch state {
        case .vermont:      Color(red: 0.13, green: 0.48, blue: 0.31)
        case .newHampshire: Color(red: 0.11, green: 0.33, blue: 0.52)
        }
    }

    /// Per-category color, used on chips, pins, and the card icon.
    static func tint(for category: EventCategory) -> Color {
        switch category {
        case .music:     Color(red: 0.55, green: 0.25, blue: 0.75)
        case .arts:      Color(red: 0.82, green: 0.31, blue: 0.44)
        case .food:      Color(red: 0.85, green: 0.48, blue: 0.13)
        case .outdoors:  Color(red: 0.15, green: 0.53, blue: 0.33)
        case .community: Color(red: 0.20, green: 0.45, blue: 0.72)
        case .family:    Color(red: 0.90, green: 0.60, blue: 0.15)
        case .sports:    Color(red: 0.75, green: 0.28, blue: 0.22)
        case .nightlife: Color(red: 0.29, green: 0.30, blue: 0.62)
        }
    }

    static let cardCorner: CGFloat = 16
    static let chipCorner: CGFloat = 20

    /// Warm off-white in light mode, warm near-black in dark. Slightly warmer
    /// than the system grays, which reads more like paper and less like a
    /// settings screen. Defined in code so there is no asset to keep in sync.
    static var pageBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.068, blue: 0.062, alpha: 1)
                : UIColor(red: 0.98, green: 0.972, blue: 0.957, alpha: 1)
        })
    }

    /// Card surface that sits a step off `pageBackground`.
    static var cardBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.117, blue: 0.11, alpha: 1)
                : UIColor.white
        })
    }

    /// The header gradient behind the Discover title.
    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [tint(for: .vermont), tint(for: .newHampshire)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Typography

extension Font {
    /// Serif display face (New York) for titles. The editorial counterpart to
    /// SF, which stays on body copy and controls.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Serif at a semantic size, so Dynamic Type still scales it.
    static func display(_ style: Font.TextStyle, _ weight: Font.Weight = .bold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

// MARK: - Shared modifiers

extension View {
    /// Standard card surface: paper-toned ground, soft corner, hairline border.
    func cardSurface() -> some View {
        self
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cardCorner))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardCorner)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
    }

    /// Small, letterspaced, uppercase label — the "overline" above a title.
    func overline(_ tint: Color = .secondary) -> some View {
        self
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(tint)
    }
}

/// Hairline rule used to close a masthead or a section header.
struct Rule: View {
    var opacity: Double = 0.18

    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(opacity))
            .frame(height: 0.5)
    }
}
