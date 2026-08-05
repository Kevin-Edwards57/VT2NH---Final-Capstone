//
//  TownsView.swift
//  VT2NH
//
//  Browse the ten covered towns as photo cards, grouped by state.
//

import SwiftUI

struct TownsView: View {
    @Bindable var store: EventStore

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(USState.allCases) { state in
                        Section {
                            ForEach(LocationCatalog.towns.filter { $0.state == state }) { town in
                                NavigationLink(value: town) {
                                    TownCard(town: town, eventCount: eventCount(for: town))
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack {
                                Text(state.rawValue)
                                    .font(.title3.bold())
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()

                Text("Photos and descriptions from Wikipedia and Wikimedia Commons")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Towns")
            .navigationDestination(for: AppLocation.self) { town in
                TownDetailView(town: town, store: store)
            }
            .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        }
    }

    private func eventCount(for town: AppLocation) -> Int {
        store.events.filter {
            $0.town.localizedCaseInsensitiveCompare(town.town) == .orderedSame
        }.count
    }
}

// MARK: - Card

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
