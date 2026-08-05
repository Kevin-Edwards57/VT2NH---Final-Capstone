//
//  EventStore.swift
//  VT2NH
//
//  Single source of truth for the browsing experience: what was loaded, what
//  the user is filtering by, and what the list should therefore show.
//
//  Uses the @Observable macro rather than ObservableObject — SwiftUI tracks
//  only the properties a given view actually reads, so changing `searchText`
//  does not redraw the map.
//

import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class EventStore {

    // MARK: Loaded state

    private(set) var events: [Event] = []
    private(set) var isLoading = false
    private(set) var loadError: String?
    /// Which source the visible events came from, shown under the list.
    private(set) var sourceLabel = ""

    // MARK: Filters

    /// nil means "everywhere in VT & NH".
    var selectedTown: AppLocation? {
        didSet { Task { await load() } }
    }
    var selectedCategories: Set<EventCategory> = []
    var searchText = ""
    var freeOnly = false

    // MARK: Sources

    private let bundled = BundledEventProvider()
    private let live = TicketmasterProvider()
    private let radiusMiles = 25

    /// Geographic middle of the coverage area, used when no town is selected.
    private static let region = AppLocation(
        id: "region", town: "Vermont & New Hampshire", state: .vermont,
        latitude: 43.9000, longitude: -72.5000,
        blurb: "Everything the app covers.",
        wikipediaTitle: "Vermont",
        fallbackCommonsFile: nil
    )

    var isUsingLiveData: Bool { live != nil }

    // MARK: Loading

    func load() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let target = selectedTown ?? Self.region

        // The bundled feed is the floor — it must never fail to produce events.
        var merged: [Event]
        do {
            merged = selectedTown == nil
                ? try bundled.allEvents()
                : try await bundled.events(near: target, radiusMiles: radiusMiles)
        } catch {
            merged = []
            loadError = "Could not read the bundled event feed."
        }
        var label = bundled.attribution

        // Live data is a bonus. A failure here is not an error the user needs
        // to see — they still have a full list.
        if let live {
            do {
                let liveRadius = selectedTown == nil ? 120 : radiusMiles
                let liveEvents = try await live.events(near: target, radiusMiles: liveRadius)
                if !liveEvents.isEmpty {
                    merged.append(contentsOf: liveEvents)
                    label = "\(live.attribution) + sample feed"
                }
            } catch {
                label = bundled.attribution + " (live feed unavailable)"
            }
        }

        events = Self.deduplicated(merged).sorted { $0.start < $1.start }
        sourceLabel = label
    }

    /// Ticketmaster and the bundled feed can describe the same show. Same name
    /// on the same calendar day is close enough to call it a duplicate.
    private static func deduplicated(_ events: [Event]) -> [Event] {
        var seen = Set<String>()
        return events.filter { event in
            let day = Calendar.current.startOfDay(for: event.start)
            let key = "\(event.name.lowercased())|\(day.timeIntervalSince1970)"
            return seen.insert(key).inserted
        }
    }

    // MARK: Derived

    var filteredEvents: [Event] {
        events.filter { event in
            if !selectedCategories.isEmpty && !selectedCategories.contains(event.category) {
                return false
            }
            if freeOnly && !event.isFree { return false }

            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return true }
            return event.name.localizedCaseInsensitiveContains(query)
                || event.summary.localizedCaseInsensitiveContains(query)
                || event.venue.name.localizedCaseInsensitiveContains(query)
                || event.town.localizedCaseInsensitiveContains(query)
        }
    }

    /// Filtered events grouped into Today / Tomorrow / This Week / Later,
    /// with empty buckets dropped.
    var sections: [(bucket: TimeBucket, events: [Event])] {
        let grouped = Dictionary(grouping: filteredEvents) { TimeBucket.bucket(for: $0.start) }
        return TimeBucket.allCases.compactMap { bucket in
            guard let events = grouped[bucket], !events.isEmpty else { return nil }
            return (bucket, events)
        }
    }

    var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || freeOnly || !searchText.isEmpty
    }

    func clearFilters() {
        selectedCategories.removeAll()
        freeOnly = false
        searchText = ""
    }

    func toggle(_ category: EventCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    /// Events sorted by distance from a point — used by the "Near me" mode.
    func eventsSortedByDistance(from location: CLLocation) -> [Event] {
        filteredEvents.sorted { $0.distance(from: location) < $1.distance(from: location) }
    }
}
