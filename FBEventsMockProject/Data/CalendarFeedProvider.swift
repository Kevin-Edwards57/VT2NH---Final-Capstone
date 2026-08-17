//
//  CalendarFeedProvider.swift
//  VT2NH
//
//  Real events, pulled automatically from public iCalendar feeds. No API key,
//  no account, no quota — these are published calendars meant to be subscribed
//  to, so the app just reads them.
//
//  Coverage is honest about itself: these feeds were found by probing 60
//  library, museum, theatre, college and municipal sites, and seven publish a
//  working .ics across six towns. Those towns get live data; the rest fall
//  back to the bundled feed. Adding one is a single line here once a feed is
//  found — most sites simply do not publish one.
//

import Foundation

// MARK: - Registry

struct CalendarFeed: Sendable {
    /// Matches `AppLocation.id` so the town's real coordinates can be used.
    let townID: String
    let venueName: String
    let url: URL

    static let all: [CalendarFeed] = [
        CalendarFeed(townID: "montpelier",
                     venueName: "Kellogg-Hubbard Library",
                     url: URL(string: "https://www.kellogghubbard.org/events/?ical=1")!),
        CalendarFeed(townID: "brattleboro",
                     venueName: "Brooks Memorial Library",
                     url: URL(string: "https://brookslibraryvt.org/events/?ical=1")!),
        CalendarFeed(townID: "woodstock",
                     venueName: "Norman Williams Public Library",
                     url: URL(string: "https://normanwilliams.org/events/?ical=1")!),
        CalendarFeed(townID: "bennington",
                     venueName: "Bennington Museum",
                     url: URL(string: "https://benningtonmuseum.org/events/?ical=1")!),
        CalendarFeed(townID: "shelburne",
                     venueName: "Shelburne Museum",
                     url: URL(string: "https://shelburnemuseum.org/events/?ical=1")!),
        CalendarFeed(townID: "woodstock",
                     venueName: "Billings Farm & Museum",
                     url: URL(string: "https://billingsfarm.org/events/?ical=1")!),
        CalendarFeed(townID: "middlebury",
                     venueName: "Ilsley Public Library",
                     url: URL(string: "https://ilsleypubliclibrary.org/events/?ical=1")!)
    ]
}

// MARK: - Provider

struct CalendarFeedProvider: EventProviding {
    let attribution = "Live library and museum calendars"

    private let session: URLSession
    private let feeds: [CalendarFeed]
    /// Guards against a feed that suddenly returns thousands of entries.
    private let maxEventsPerFeed = 40

    init(feeds: [CalendarFeed] = CalendarFeed.all, session: URLSession? = nil) {
        self.feeds = feeds
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 12
            config.httpAdditionalHeaders = [
                "User-Agent": "VT2NH/1.0 (iOS app; public calendar reader)"
            ]
            config.requestCachePolicy = .returnCacheDataElseLoad
            self.session = URLSession(configuration: config)
        }
    }

    func events(near location: AppLocation, radiusMiles: Int) async throws -> [Event] {
        let relevant = feeds.filter { $0.townID == location.id }
        return await fetch(relevant.isEmpty ? [] : relevant)
    }

    /// Every feed, for the "all towns" view.
    func allEvents() async -> [Event] {
        await fetch(feeds)
    }

    /// Feeds are fetched concurrently and failures are dropped, not thrown —
    /// one library being down must never empty the screen.
    private func fetch(_ feeds: [CalendarFeed]) async -> [Event] {
        guard !feeds.isEmpty else { return [] }

        return await withTaskGroup(of: [Event].self) { group in
            for feed in feeds {
                group.addTask { await events(from: feed) }
            }
            var all: [Event] = []
            for await batch in group { all.append(contentsOf: batch) }
            return all.sorted { $0.start < $1.start }
        }
    }

    private func events(from feed: CalendarFeed) async -> [Event] {
        guard let town = LocationCatalog.towns.first(where: { $0.id == feed.townID }),
              let (data, response) = try? await session.data(from: feed.url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let text = String(data: data, encoding: .utf8)
        else { return [] }

        let now = Date.now
        return ICSParser.parse(text)
            .compactMap { entry -> Event? in
                guard let start = entry.start, start >= now,
                      let title = entry.summary, !title.isEmpty
                else { return nil }

                return Event(
                    id: "ics-\(feed.townID)-\(entry.uid ?? title)-\(Int(start.timeIntervalSince1970))",
                    name: title,
                    summary: entry.description?.isEmpty == false
                        ? String(entry.description!.prefix(400))
                        : "Presented at \(feed.venueName).",
                    category: Self.category(for: title),
                    start: start,
                    end: entry.end,
                    // The feed gives a postal address, not coordinates, so the
                    // town's own point is used. The venue really is in that
                    // town, so the pin is honest even if it is not exact.
                    venue: Venue(name: venueName(from: entry, fallback: feed.venueName),
                                 address: entry.location,
                                 latitude: town.latitude,
                                 longitude: town.longitude),
                    town: town.town,
                    state: town.state,
                    ticketURL: entry.url.flatMap(URL.init(string:)),
                    priceLabel: "Free"
                )
            }
            .prefix(maxEventsPerFeed)
            .map { $0 }
    }

    /// iCalendar LOCATION is usually "Venue, 123 Main St, Town, ST, 05602".
    /// The first component is the venue.
    private func venueName(from entry: ICSEvent, fallback: String) -> String {
        guard let location = entry.location,
              let first = location.components(separatedBy: ",").first,
              !first.trimmingCharacters(in: .whitespaces).isEmpty
        else { return fallback }
        return first.trimmingCharacters(in: .whitespaces)
    }

    /// Feeds carry no category, so it is inferred from the title. Library
    /// calendars are dominated by story times, book groups and craft sessions,
    /// which is why community is the default rather than music.
    static func category(for title: String) -> EventCategory {
        let text = title.lowercased()
        let map: [(EventCategory, [String])] = [
            (.family,    ["story time", "storytime", "kids", "children", "toddler", "baby",
                          "teen", "lego", "craft", "family", "youth"]),
            (.music,     ["concert", "music", "band", "jazz", "choir", "sing", "orchestra", "open mic"]),
            (.arts,      ["author", "book", "poetry", "reading", "film", "movie", "art",
                          "gallery", "theater", "theatre", "writing"]),
            (.food,      ["food", "cooking", "bake", "tasting", "dinner", "lunch", "coffee"]),
            (.outdoors,  ["hike", "walk", "garden", "nature", "birding", "trail", "outdoor"]),
            (.sports,    ["yoga", "fitness", "run", "chess", "game night"]),
            (.nightlife, ["trivia", "comedy"])
        ]
        for (category, keywords) in map where keywords.contains(where: text.contains) {
            return category
        }
        return .community
    }
}
