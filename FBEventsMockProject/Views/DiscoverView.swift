//
//  DiscoverView.swift
//  VT2NH
//
//  The main browsing screen: pick a town, filter by category, search, and
//  scroll a calendar grouped by how soon each event is.
//

import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Bindable var store: EventStore
    var locationProvider: LocationProvider

    @Query private var savedEvents: [SavedEvent]
    @State private var showingTownPicker = false

    private var savedIDs: Set<String> {
        Set(savedEvents.map(\.eventID))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
                    header

                    if store.isLoading && store.events.isEmpty {
                        SkeletonFeed()
                    } else if store.filteredEvents.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.sections, id: \.bucket.id) { section in
                            Section {
                                // Each section leads with one full-width hero and
                                // lists the rest densely. Uniform cards across 105
                                // events give the eye nothing to anchor on.
                                ForEach(Array(section.events.enumerated()), id: \.element.id) { index, event in
                                    NavigationLink(value: event) {
                                        if index == 0 {
                                            EventCard(event: event,
                                                      isSaved: savedIDs.contains(event.id))
                                        } else {
                                            CompactEventRow(event: event,
                                                            isSaved: savedIDs.contains(event.id))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                            } header: {
                                SectionHeader(title: section.bucket.rawValue,
                                              count: section.events.count)
                            }
                        }

                        attribution
                    }
                }
                .padding(.vertical)
            }
            .background(Theme.pageBackground)
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
            .searchable(text: $store.searchText, prompt: "Search events, venues, towns")
            .refreshable { await store.load() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingTownPicker = true
                    } label: {
                        // Filled variant signals that a town scope is active.
                        Label("Change town",
                              systemImage: store.selectedTown == nil
                                  ? "line.3.horizontal.decrease.circle"
                                  : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingTownPicker) {
                TownPickerView(store: store, locationProvider: locationProvider)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Masthead — an overline, a serif title, and a rule beneath.
                Text(store.selectedTown.map { "\($0.state.rawValue) · \($0.state.abbreviation)" }
                     ?? "Vermont & New Hampshire")
                    .overline()

                Text(store.selectedTown?.town ?? "What's On")
                    .font(.display(40))
                    .contentTransition(.numericText())

                Rule().padding(.trailing, 40)

                Text(store.selectedTown?.blurb
                     ?? "\(store.filteredEvents.count) events across \(LocationCatalog.towns.count) towns")
                    .font(.callout)
                    .italic()
                    .foregroundStyle(.secondary)

                // Scoping to a town is sticky and easy to forget you set. Without
                // a visible way out, the app just looks like it only covers one
                // town. This is that way out.
                if let town = store.selectedTown {
                    Button {
                        withAnimation(.snappy) { store.selectedTown = nil }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.circle.fill")
                            Text("Only \(town.town)")
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.tint(for: town.state).opacity(0.16), in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                    .accessibilityLabel("Showing only \(town.name). Tap to show all towns.")
                }
            }
            .padding(.horizontal)

            FilterBar(store: store)

            if store.hasActiveFilters {
                Button("Clear filters", systemImage: "xmark.circle.fill") {
                    withAnimation(.snappy) { store.clearFilters() }
                }
                .font(.footnote)
                .padding(.horizontal)
            }
        }
    }

    // MARK: States

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No events match", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text(store.hasActiveFilters
                 ? "Try clearing a filter or widening your search."
                 : "There is nothing scheduled here right now.")
        } actions: {
            if store.hasActiveFilters {
                Button("Clear filters") {
                    withAnimation(.snappy) { store.clearFilters() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 40)
    }

    private var attribution: some View {
        VStack(spacing: 4) {
            Text(store.sourceLabel)
            Text("Weather by Open-Meteo.com · CC BY 4.0")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.display(.title3))
                Spacer()
                Text("\(count)")
                    .overline()
            }
            Rule(opacity: 0.25)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }
}
