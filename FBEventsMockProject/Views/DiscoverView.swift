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
                LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                    header

                    if store.isLoading && store.events.isEmpty {
                        loadingState
                    } else if store.filteredEvents.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.sections, id: \.bucket.id) { section in
                            Section {
                                ForEach(section.events) { event in
                                    NavigationLink(value: event) {
                                        EventCard(event: event,
                                                  isSaved: savedIDs.contains(event.id))
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
            .background(Color(.systemGroupedBackground))
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
                        Label("Change town", systemImage: "line.3.horizontal.decrease.circle")
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
            VStack(alignment: .leading, spacing: 6) {
                Text(store.selectedTown?.name ?? "Vermont & New Hampshire")
                    .font(.largeTitle.bold())
                    .contentTransition(.numericText())

                Text(store.selectedTown?.blurb
                     ?? "\(store.filteredEvents.count) events across \(LocationCatalog.towns.count) towns")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading events…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

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
        HStack {
            Text(title)
                .font(.title3.bold())
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
