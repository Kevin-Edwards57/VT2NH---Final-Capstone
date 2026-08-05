//
//  TownPhotoView.swift
//  VT2NH
//
//  Photo banners for towns and states. Both pull from Wikimedia and share one
//  presentation layer, so they crossfade, dim, and credit identically.
//
//  Every banner falls back to a tinted gradient, which means a slow network or
//  a subject with no usable photo still looks deliberate rather than broken.
//

import SwiftUI

// MARK: - Presentation

/// Pure presentation — takes an already-loaded photo and renders it.
struct PhotoBanner: View {
    let photo: TownPhoto?
    let height: CGFloat
    var tint: Color
    var showsAttribution = false
    /// How dark the bottom of the image gets, for text laid over it.
    var scrimOpacity: Double = 0.65

    var body: some View {
        // The gradient is the only thing that sets this view's size. The photo
        // rides in an overlay because `scaledToFill` on a very wide source —
        // the Vermont panorama is 7064px across — would otherwise drive the
        // layout width and push overlaid titles off screen.
        LinearGradient(colors: [tint.opacity(0.85), tint.opacity(0.45)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: height * 0.3))
                    .foregroundStyle(.white.opacity(0.12))
            }
            .overlay {
                if let url = photo?.url {
                    AsyncImage(url: url,
                               transaction: .init(animation: .easeOut(duration: 0.35))) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill().transition(.opacity)
                        }
                    }
                }
            }
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(scrimOpacity)],
                               startPoint: .center, endPoint: .bottom)
            }
            .clipped()
        // Credit sits bottom-trailing so it never collides with a title, which
        // callers overlay at bottom-leading.
        .overlay(alignment: .bottomTrailing) {
            if showsAttribution, let attribution = photo?.attribution {
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
    }
}

// MARK: - Town

struct TownPhotoView: View {
    let town: AppLocation
    var height: CGFloat
    var showsAttribution = false

    @State private var profile: TownProfile?

    var body: some View {
        PhotoBanner(photo: profile?.photo,
                    height: height,
                    tint: Theme.tint(for: town.state),
                    showsAttribution: showsAttribution)
            .task(id: town.id) {
                profile = await WikipediaService.shared.profile(for: town)
            }
    }
}

// MARK: - State

struct StatePhotoView: View {
    let state: USState
    var height: CGFloat
    var showsAttribution = false

    @State private var photo: TownPhoto?

    var body: some View {
        PhotoBanner(photo: photo,
                    height: height,
                    tint: Theme.tint(for: state),
                    showsAttribution: showsAttribution,
                    scrimOpacity: 0.75)
            .task(id: state.id) {
                photo = await WikipediaService.shared.photo(commonsFile: state.heroCommonsFile)
            }
    }
}
