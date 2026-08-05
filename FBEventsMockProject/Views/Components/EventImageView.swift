//
//  EventImageView.swift
//  VT2NH
//
//  Artwork for an event, resolved in order of how specific it is:
//
//    1. The event's own image, when a live source supplied one.
//    2. Its town's Wikipedia photo — always available, always relevant.
//    3. A category-tinted gradient, if both are unreachable.
//
//  An earlier attempt matched venues against Commons by name. It was wrong
//  often enough to be unusable — a Stowe walking path resolved to a recreation
//  area in England, a Concord park to one in Australia — so the town photo,
//  which is verified per town, is the fallback instead.
//

import SwiftUI

struct EventImageView: View {
    let event: Event
    var height: CGFloat
    var showsAttribution = false

    @State private var townPhoto: TownPhoto?

    /// The event's own artwork wins; otherwise the town's.
    private var photo: TownPhoto? {
        if let imageURL = event.imageURL {
            return TownPhoto(url: imageURL, credit: nil, license: nil)
        }
        return townPhoto
    }

    var body: some View {
        PhotoBanner(photo: photo,
                    height: height,
                    tint: Theme.tint(for: event.category),
                    showsAttribution: showsAttribution)
            .task(id: event.id) {
                // Only reach for a town photo when the event brought none.
                guard event.imageURL == nil,
                      let town = LocationCatalog.town(for: event) else { return }
                townPhoto = await WikipediaService.shared.profile(for: town)?.photo
            }
    }
}
