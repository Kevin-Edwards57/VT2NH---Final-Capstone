//
//  BundledFeedTests.swift
//  VT2NHTests
//
//  The bundled feed is the app's floor — if it fails, the whole product is an
//  empty screen. These assert it decodes, resolves its relative dates, and
//  stays consistent with the town catalog.
//

import Testing
import Foundation
@testable import FBEventsMockProject

@Suite("Bundled event feed")
struct BundledFeedTests {

    private let provider = BundledEventProvider()

    @Test("The feed decodes and is not empty")
    func feedDecodes() throws {
        let events = try provider.allEvents()
        #expect(events.isEmpty == false)
    }

    /// The feed stores day offsets rather than absolute dates precisely so the
    /// demo never goes stale. If this fails, the app looks abandoned.
    @Test("Every event resolves to a date in the future or today")
    func noStaleDates() throws {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let stale = try provider.allEvents().filter { $0.start < startOfToday }
        #expect(stale.isEmpty, "\(stale.count) events resolved to the past")
    }

    @Test("Events are sorted by start date")
    func sortedByDate() throws {
        let events = try provider.allEvents()
        #expect(events == events.sorted { $0.start < $1.start })
    }

    @Test("Event IDs are unique")
    func uniqueIDs() throws {
        let events = try provider.allEvents()
        #expect(Set(events.map(\.id)).count == events.count)
    }

    /// A typo in a town name would silently orphan an event: it would never
    /// appear on its town page and would get no photo.
    @Test("Every event belongs to a town in the catalog")
    func everyEventMapsToACatalogTown() throws {
        let orphans = try provider.allEvents().filter { LocationCatalog.town(for: $0) == nil }
        #expect(orphans.isEmpty,
                "orphaned: \(orphans.map { "\($0.name) (\($0.town), \($0.state.abbreviation))" })")
    }

    @Test("Every town in the catalog has at least one event")
    func everyTownHasEvents() throws {
        let events = try provider.allEvents()
        let empty = LocationCatalog.towns.filter { town in
            !events.contains { $0.matches(town) }
        }
        #expect(empty.isEmpty, "towns with no events: \(empty.map(\.name))")
    }

    @Test("Deduplication does not discard any bundled event")
    func feedSurvivesDeduplication() throws {
        let events = try provider.allEvents()
        #expect(EventStore.deduplicated(events).count == events.count)
    }

    @Test("Coordinates fall inside the Vermont/New Hampshire region")
    func coordinatesAreInRegion() throws {
        let outOfRegion = try provider.allEvents().filter {
            !(42.5...45.1).contains($0.venue.latitude)
                || !((-73.6)...(-70.5)).contains($0.venue.longitude)
        }
        #expect(outOfRegion.isEmpty,
                "out of region: \(outOfRegion.map { "\($0.name) @ \($0.venue.latitude),\($0.venue.longitude)" })")
    }

    @Test("Filtering near a town returns only nearby events")
    func nearTownFiltering() async throws {
        let burlington = try #require(LocationCatalog.towns.first { $0.id == "burlington" })
        let nearby = try await provider.events(near: burlington, radiusMiles: 25)

        #expect(nearby.isEmpty == false)
        let center = burlington.location
        #expect(nearby.allSatisfy { $0.matches(burlington) || $0.distance(from: center) <= 25 * 1609.34 })
    }
}

// MARK: - Configuration

@Suite("Optional live source")
struct SecretsTests {

    /// The whole degradation story rests on this: with no key configured the
    /// live provider must refuse to construct rather than fail at runtime.
    @Test("Ticketmaster provider is nil when no key is configured")
    func providerIsNilWithoutKey() {
        if Secrets.ticketmasterAPIKey == nil {
            #expect(TicketmasterProvider() == nil)
        } else {
            // A key is present in this checkout; the nil path cannot be tested.
            #expect(TicketmasterProvider() != nil)
        }
    }

    @Test("The placeholder value is treated as absent")
    func placeholderIsNotAKey() {
        #expect(Secrets.ticketmasterAPIKey != "YOUR_TICKETMASTER_API_KEY")
    }
}
