//
//  TownPhotoView.swift
//  VT2NH
//
//  Loads a town's Wikipedia photo and crossfades it in. Falls back to a
//  state-tinted gradient, so a slow network or a town with no usable photo
//  still looks deliberate rather than broken.
//

import SwiftUI

struct TownPhotoView: View {
    let town: AppLocation
    var height: CGFloat
    var showsAttribution = false

    @State private var profile: TownProfile?
    @State private var didLoad = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            placeholder

            if let url = profile?.photo?.url {
                AsyncImage(url: url, transaction: .init(animation: .easeOut(duration: 0.35))) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    }
                }
            }

            // Keeps overlaid text legible regardless of how bright the photo is.
            LinearGradient(colors: [.clear, .black.opacity(0.65)],
                           startPoint: .center, endPoint: .bottom)

        }
        .frame(height: height)
        // Credit sits bottom-trailing so it never collides with the town name,
        // which callers overlay at bottom-leading.
        .overlay(alignment: .bottomTrailing) {
            if showsAttribution, let attribution = profile?.photo?.attribution {
                Text(attribution)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.35), in: .capsule)
                    .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .task {
            guard !didLoad else { return }
            didLoad = true
            profile = await WikipediaService.shared.profile(for: town)
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Theme.tint(for: town.state).opacity(0.85),
                     Theme.tint(for: town.state).opacity(0.45)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: height * 0.3))
                .foregroundStyle(.white.opacity(0.12))
        }
    }
}
