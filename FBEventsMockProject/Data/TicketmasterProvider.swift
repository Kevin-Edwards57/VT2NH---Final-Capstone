//
//  TicketmasterProvider.swift
//  VT2NH
//
//  Live events from the Ticketmaster Discovery API v2.
//  Free tier: 5,000 requests/day, 5 requests/second.
//  Get a key at https://developer.ticketmaster.com — it is instant and free.
//
//  The key is read from Secrets.plist, which is gitignored — copy
//  Secrets.example.plist to Secrets.plist and paste your key in. Without a key
//  this provider reports itself unavailable and the app falls back to the
//  bundled feed, which is why a fresh clone still runs.
//
//  The previous version of this app hardcoded a Facebook token directly in
//  source and pushed it to a public repo. This is the fix for that.
//

import Foundation

struct TicketmasterProvider: EventProviding {
    let attribution = "Live data from Ticketmaster"

    private let apiKey: String
    private let session: URLSession

    /// Fails to build when no key is configured, which is the signal the
    /// coordinator uses to skip the live source entirely.
    init?(session: URLSession = .shared) {
        guard let key = Secrets.ticketmasterAPIKey else { return nil }
        self.apiKey = key
        self.session = session
    }

    func events(near location: AppLocation, radiusMiles: Int) async throws -> [Event] {
        var components = URLComponents(string: "https://app.ticketmaster.com/discovery/v2/events.json")!
        components.queryItems = [
            .init(name: "apikey", value: apiKey),
            .init(name: "latlong", value: "\(location.latitude),\(location.longitude)"),
            .init(name: "radius", value: String(radiusMiles)),
            .init(name: "unit", value: "miles"),
            .init(name: "size", value: "60"),
            .init(name: "sort", value: "date,asc"),
            .init(name: "startDateTime", value: Self.iso8601Z.string(from: .now))
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else {
            throw EventProviderError.badResponse(status: -1)
        }
        // 429 is the documented rate-limit response; treat it as "no live data
        // right now" rather than an error the user has to look at.
        guard http.statusCode == 200 else {
            throw EventProviderError.badResponse(status: http.statusCode)
        }

        let payload = try JSONDecoder().decode(DiscoveryResponse.self, from: data)
        return (payload.embedded?.events ?? []).compactMap { $0.asEvent(fallbackTown: location) }
    }

    /// Discovery requires seconds precision with a literal Z and no fractional part.
    private static let iso8601Z: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
}

// MARK: - Discovery wire format
//
// Only the fields the app actually renders are modeled. Discovery returns a
// great deal more; decoding all of it would be churn with no payoff.

private struct DiscoveryResponse: Decodable {
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey { case embedded = "_embedded" }

    struct Embedded: Decodable {
        let events: [DiscoveryEvent]
    }
}

private struct DiscoveryEvent: Decodable {
    let id: String
    let name: String
    let url: String?
    let info: String?
    let description: String?
    let dates: Dates?
    let classifications: [Classification]?
    let priceRanges: [PriceRange]?
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey {
        case id, name, url, info, description, dates, classifications, priceRanges
        case embedded = "_embedded"
    }

    struct Dates: Decodable {
        let start: Start?
        struct Start: Decodable {
            let dateTime: String?
            let localDate: String?
        }
    }

    struct Classification: Decodable {
        let segment: Named?
        let genre: Named?
        struct Named: Decodable { let name: String? }
    }

    struct PriceRange: Decodable {
        let min: Double?
        let max: Double?
        let currency: String?
    }

    struct Embedded: Decodable {
        let venues: [DiscoveryVenue]?
    }

    struct DiscoveryVenue: Decodable {
        let name: String?
        let city: City?
        let state: State?
        let address: Address?
        let location: Location?

        struct City: Decodable { let name: String? }
        struct State: Decodable { let name: String?; let stateCode: String? }
        struct Address: Decodable { let line1: String? }
        struct Location: Decodable { let latitude: String?; let longitude: String? }
    }

    /// Maps a Discovery record onto the app's own model. Returns nil when the
    /// record lacks the two things every screen depends on: a date and a point.
    func asEvent(fallbackTown: AppLocation) -> Event? {
        guard let venue = embedded?.venues?.first,
              let latText = venue.location?.latitude, let lat = Double(latText),
              let lonText = venue.location?.longitude, let lon = Double(lonText),
              let start = parsedStart()
        else { return nil }

        let stateName = venue.state?.name ?? fallbackTown.state.rawValue
        let state = USState(rawValue: stateName) ?? fallbackTown.state

        return Event(
            id: "tm-\(id)",
            name: name,
            summary: info ?? description ?? "Presented at \(venue.name ?? "a local venue").",
            category: mappedCategory(),
            start: start,
            end: nil,
            venue: Venue(name: venue.name ?? "Venue TBA",
                         address: venue.address?.line1,
                         latitude: lat,
                         longitude: lon),
            town: venue.city?.name ?? fallbackTown.town,
            state: state,
            ticketURL: url.flatMap(URL.init(string:)),
            priceLabel: priceLabel()
        )
    }

    private func parsedStart() -> Date? {
        if let dateTime = dates?.start?.dateTime,
           let date = ISO8601DateFormatter().date(from: dateTime) {
            return date
        }
        // Some listings are date-only; put them at a plausible evening hour.
        if let localDate = dates?.start?.localDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            if let day = formatter.date(from: localDate) {
                return Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: day)
            }
        }
        return nil
    }

    /// Folds Discovery's segment/genre taxonomy into the app's eight categories.
    private func mappedCategory() -> EventCategory {
        let segment = classifications?.first?.segment?.name?.lowercased() ?? ""
        let genre = classifications?.first?.genre?.name?.lowercased() ?? ""
        let text = segment + " " + genre

        if text.contains("music") { return .music }
        if text.contains("sports") { return .sports }
        if text.contains("family") || text.contains("children") { return .family }
        if text.contains("comedy") { return .nightlife }
        if text.contains("arts") || text.contains("theatre") || text.contains("theater") { return .arts }
        if text.contains("food") { return .food }
        return .community
    }

    private func priceLabel() -> String? {
        guard let range = priceRanges?.first, let min = range.min else { return nil }
        if let max = range.max, max > min {
            return "$\(Int(min))–$\(Int(max))"
        }
        return "$\(Int(min))"
    }
}
