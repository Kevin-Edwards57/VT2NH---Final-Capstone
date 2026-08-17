//
//  SkeletonView.swift
//  VT2NH
//
//  Placeholder shapes shown while the first load is in flight. A spinner tells
//  you nothing is here yet; a skeleton tells you what is about to arrive and
//  keeps the layout from jumping when it does.
//

import SwiftUI

/// A shimmering rounded rectangle sized like the content it stands in for.
struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat
    var corner: CGFloat = 6

    @State private var shift = false

    var body: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color.primary.opacity(0.08))
            .frame(width: width, height: height)
            .overlay {
                // A soft highlight sweeping left to right.
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.primary.opacity(0.06), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: shift ? geo.size.width : -geo.size.width * 0.5)
                }
            }
            .clipShape(.rect(cornerRadius: corner))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    shift = true
                }
            }
    }
}

/// Stand-in for the featured hero card.
struct SkeletonFeaturedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBlock(height: 150, corner: 0)
            VStack(alignment: .leading, spacing: 7) {
                SkeletonBlock(width: 70, height: 8)
                SkeletonBlock(width: 210, height: 13)
                SkeletonBlock(width: 150, height: 10)
            }
            .padding(12)
        }
        .cardSurface()
    }
}

/// Stand-in for a compact row.
struct SkeletonCompactRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SkeletonBlock(width: 76, height: 76, corner: 10)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock(width: 60, height: 8)
                SkeletonBlock(width: 180, height: 12)
                SkeletonBlock(width: 130, height: 9)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .cardSurface()
    }
}

/// The whole first-load state: one hero and a few rows.
struct SkeletonFeed: View {
    var body: some View {
        VStack(spacing: 12) {
            SkeletonFeaturedCard()
            ForEach(0..<4, id: \.self) { _ in SkeletonCompactRow() }
        }
        .padding(.horizontal)
        .accessibilityLabel("Loading events")
        .accessibilityHidden(false)
    }
}
