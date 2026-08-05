//
//  TownsView.swift
//  VT2NH
//
//  Entry point for browsing by place: pick a state, then a town.
//  Two large photo cards, because that is the whole choice at this level.
//

import SwiftUI

struct TownsView: View {
    @Bindable var store: EventStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(USState.allCases) { state in
                        NavigationLink(value: state) {
                            StateCard(state: state, eventCount: eventCount(in: state))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Photos and descriptions from Wikipedia and Wikimedia Commons")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Browse")
            .navigationDestination(for: USState.self) { state in
                StateTownsView(state: state, store: store)
            }
            .navigationDestination(for: AppLocation.self) { town in
                TownDetailView(town: town, store: store)
            }
            .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        }
    }

    private func eventCount(in state: USState) -> Int {
        store.events.filter { $0.state == state }.count
    }
}

// MARK: - State card

private struct StateCard: View {
    let state: USState
    let eventCount: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            StatePhotoView(state: state, height: 200)

            VStack(alignment: .leading, spacing: 6) {
                Text(state.rawValue)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Text(state.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Label("\(state.towns.count) towns", systemImage: "building.2.fill")
                    Label("\(eventCount) events", systemImage: "calendar")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.top, 2)
            }
            .padding(16)

            HStack {
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(16)
            }
        }
        .clipShape(.rect(cornerRadius: Theme.cardCorner))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardCorner)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
        }
    }
}

// MARK: - Towns within a state

struct StateTownsView: View {
    let state: USState
    var store: EventStore

    @State private var searchText = ""

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    private var towns: [AppLocation] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return state.towns }
        return state.towns.filter { $0.town.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            StatePhotoView(state: state, height: 140, showsAttribution: true)
                .overlay(alignment: .bottomLeading) {
                    Text(state.tagline)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(14)
                }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(towns) { town in
                    NavigationLink(value: town) {
                        TownCard(town: town, eventCount: store.events.filter { $0.matches(town) }.count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            if towns.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .padding(.top, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(state.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search \(state.rawValue) towns")
    }
}

// MARK: - Town card

private struct TownCard: View {
    let town: AppLocation
    let eventCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                TownPhotoView(town: town, height: 150)

                VStack(alignment: .leading, spacing: 2) {
                    Text(town.town)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(town.state.abbreviation)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(town.blurb)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Label("\(eventCount) event\(eventCount == 1 ? "" : "s")",
                      systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.tint(for: town.state))
            }
            .padding(12)
        }
        .cardSurface()
    }
}
