//
//  TownDetailView.swift
//  VT2NH
//
//  One town: a full-bleed photo, the Wikipedia summary with a link through to
//  the article, a map, and everything happening there.
//

import SwiftUI
import MapKit

struct TownDetailView: View {
    let town: AppLocation
    var store: EventStore

    @Environment(\.openURL) private var openURL
    @State private var profile: TownProfile?
    @State private var isExpanded = false

    private var events: [Event] {
        store.events
            .filter { $0.matches(town) }
            .sorted { $0.start < $1.start }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                summaryCard
                mapCard
                eventsSection
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(town.town)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
        .task {
            profile = await WikipediaService.shared.profile(for: town)
        }
    }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            TownPhotoView(town: town, height: 260, showsAttribution: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(town.state.rawValue.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(1.2)

                Text(town.town)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)

                Text(town.blurb)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
            .padding(.bottom, 14)
        }
    }

    // MARK: Wikipedia

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("About \(town.town)", systemImage: "book.fill")
                .font(.headline)

            if let summary = profile?.summary, !summary.isEmpty {
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(isExpanded ? nil : 4)

                Button(isExpanded ? "Show less" : "Read more") {
                    withAnimation(.snappy) { isExpanded.toggle() }
                }
                .font(.footnote.weight(.semibold))
            } else {
                // Article text is still in flight, or the device is offline.
                Text(town.blurb)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button {
                if let url = profile?.articleURL ?? town.wikipediaURL {
                    openURL(url)
                }
            } label: {
                Label("Read on Wikipedia", systemImage: "safari.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(14)
        .cardSurface()
        .padding(.horizontal)
    }

    // MARK: Map

    private var mapCard: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: town.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)
        )), interactionModes: []) {
            ForEach(events) { event in
                Marker(event.name, systemImage: event.category.symbol,
                       coordinate: event.coordinate)
                    .tint(Theme.tint(for: event.category))
            }
        }
        .frame(height: 170)
        .clipShape(.rect(cornerRadius: Theme.cardCorner))
        .padding(.horizontal)
    }

    // MARK: Events

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What's on")
                    .font(.title3.bold())
                Spacer()
                Text("\(events.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if events.isEmpty {
                ContentUnavailableView("Nothing scheduled",
                                       systemImage: "calendar",
                                       description: Text("No events listed in \(town.town) right now."))
                    .frame(height: 180)
            } else {
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        EventCard(event: event)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
    }
}
