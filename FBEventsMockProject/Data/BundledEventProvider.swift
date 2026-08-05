//
//  BundledEventProvider.swift
//  VT2NH
//
//  Reads events.json out of the app bundle. No network, no key, works on a
//  plane. This is what makes the app runnable the moment it is cloned.
//
//  The feed stores day offsets rather than absolute dates, so a demo opened a
//  year from now still shows a full week of upcoming events.
//

import Foundation
import CoreLocation

// MARK: - Wire format

private struct FeedFile: Decodable {
    let events: [FeedEvent]
}

private struct FeedEvent: Decodable {
    let id: String
    let name: String
    let summary: String
    let category: EventCategory
    let town: String
    let state: USState
    let venue: Venue
    let dayOffset: Int
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let priceLabel: String?
    let url: String?

    /// Resolves the stored offset against today's date.
    func resolved(from referenceDate: Date, calendar: Calendar) -> Event? {
        let midnight = calendar.startOfDay(for: referenceDate)
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: midnight),
              let start = calendar.date(bySettingHour: startHour, minute: startMinute,
                                        second: 0, of: day)
        else { return nil }

        return Event(id: id,
                     name: name,
                     summary: summary,
                     category: category,
                     start: start,
                     end: calendar.date(byAdding: .minute, value: durationMinutes, to: start),
                     venue: venue,
                     town: town,
                     state: state,
                     ticketURL: url.flatMap(URL.init(string:)),
                     priceLabel: priceLabel)
    }
}

// MARK: - Provider

struct BundledEventProvider: EventProviding {
    let attribution = "Sample feed bundled with the app"

    private let resourceName: String
    private let calendar: Calendar

    init(resourceName: String = "events", calendar: Calendar = .current) {
        self.resourceName = resourceName
        self.calendar = calendar
    }

    func events(near location: AppLocation, radiusMiles: Int) async throws -> [Event] {
        let all = try loadAll()
        let radiusMeters = Double(radiusMiles) * 1609.34
        let center = location.location

        return all
            .filter { event in
                // Filed under this town, or simply close enough to it.
                // Town name alone is not unique — Manchester exists in both
                // states — so an exact match must agree on state too.
                event.matches(location) || event.distance(from: center) <= radiusMeters
            }
            .sorted { $0.start < $1.start }
    }

    /// Every event in the feed, used by the map screen and the "All towns" mode.
    func allEvents() throws -> [Event] {
        try loadAll().sorted { $0.start < $1.start }
    }

    private func loadAll() throws -> [Event] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        let feed = try JSONDecoder().decode(FeedFile.self, from: data)
        let now = Date.now
        return feed.events.compactMap { $0.resolved(from: now, calendar: calendar) }
    }
}
