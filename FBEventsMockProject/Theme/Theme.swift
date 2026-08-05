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

    /// The header gradient behind the Discover title.
    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [tint(for: .vermont), tint(for: .newHampshire)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shared modifiers

extension View {
    /// Standard card surface: grouped background, soft corner, hairline border.
    func cardSurface() -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: Theme.cardCorner))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardCorner)
                    .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
            }
    }
}
