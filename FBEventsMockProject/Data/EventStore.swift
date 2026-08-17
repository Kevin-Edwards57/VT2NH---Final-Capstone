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
    /// Real events from public library calendars. Keyless, so it always runs.
    private let calendars = CalendarFeedProvider()
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

        // Public calendar feeds: real events, no key required, so this always
        // runs. Failures are already swallowed inside the provider — one
        // library being unreachable must not empty the screen.
        let feedEvents = selectedTown == nil
            ? await calendars.allEvents()
            : ((try? await calendars.events(near: target, radiusMiles: radiusMiles)) ?? [])
        if !feedEvents.isEmpty {
            merged.append(contentsOf: feedEvents)
            label = "\(calendars.attribution) + sample feed"
        }

        // Live data is a bonus. A failure here is not an error the user needs
        // to see — they still have a full list.
        if let live {
            do {
                let liveRadius = selectedTown == nil ? 120 : radiusMiles
                let liveEvents = try await live.events(near: target, radiusMiles: liveRadius)
                if !liveEvents.isEmpty {
                    merged.append(contentsOf: liveEvents)
                    label = feedEvents.isEmpty
                        ? "\(live.attribution) + sample feed"
                        : "\(live.attribution) + library calendars + sample feed"
                }
            } catch {
                label = bundled.attribution + " (live feed unavailable)"
            }
        }

        events = Self.deduplicated(merged).sorted { $0.start < $1.start }
        sourceLabel = label
    }

    /// Pure and stateless, so it is `nonisolated` despite the type being
    /// `@MainActor` — it touches nothing that needs the main actor, and this
    /// lets it be called (and tested) from any context.
    ///
    /// Ticketmaster and the bundled feed can describe the same show, so the
    /// same event in the same place on the same day collapses to one row.
    ///
    /// Identity is name + day + **town + state**. Location has to be part of
    /// the key: across 30 towns, two places can easily run identically named
    /// events — a "Farmers Market" on the same Saturday — and keying on name
    /// and day alone would silently delete one of them. State is included
    /// because town names are not unique either; Manchester is in both.
    ///
    /// The event ID is deliberately *not* part of the key. Different providers
    /// assign different IDs to the same real-world event, so including it
    /// would defeat the deduplication entirely.
    nonisolated static func deduplicated(_ events: [Event]) -> [Event] {
        var seen = Set<String>()
        return events.filter { event in
            let day = Calendar.current.startOfDay(for: event.start)
            let key = [
                normalized(event.name),
                String(day.timeIntervalSince1970),
                normalized(event.town),
                event.state.rawValue
            ].joined(separator: "|")
            return seen.insert(key).inserted
        }
    }

    /// Trims surrounding whitespace and newlines, then case- and
    /// diacritic-folds. Locale-independent on purpose: the same two records
    /// must collapse identically regardless of the device's region, and feeds
    /// differ on padding and accents ("Dvořák" vs "Dvorak").
    nonisolated static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
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
