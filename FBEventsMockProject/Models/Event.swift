//
//  Event.swift
//  VT2NH
//
//  The core domain model. Decoded from the bundled feed, rendered by every screen.
//

import Foundation
import CoreLocation

// MARK: - Category

/// The kind of thing an event is. Drives filter chips, pin tint, and iconography.
enum EventCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case music
    case arts
    case food
    case outdoors
    case community
    case family
    case sports
    case nightlife

    var id: String { rawValue }

    var title: String {
        switch self {
        case .music:     "Music"
        case .arts:      "Arts"
        case .food:      "Food & Drink"
        case .outdoors:  "Outdoors"
        case .community: "Community"
        case .family:    "Family"
        case .sports:    "Sports"
        case .nightlife: "Nightlife"
        }
    }

    var symbol: String {
        switch self {
        case .music:     "music.note"
        case .arts:      "theatermasks.fill"
        case .food:      "fork.knife"
        case .outdoors:  "mountain.2.fill"
        case .community: "person.3.fill"
        case .family:    "figure.and.child.holdinghands"
        case .sports:    "figure.run"
        case .nightlife: "moon.stars.fill"
        }
    }
}

// MARK: - Venue

/// Where an event happens. Coordinates are what put a pin on the map.
struct Venue: Codable, Hashable, Sendable {
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Event

/// A single event. `start`/`end` are real `Date` values by the time this exists —
/// the feed stores day offsets and the provider resolves them, so the app never
/// shows a calendar full of dates that already happened.
struct Event: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let summary: String
    let category: EventCategory
    let start: Date
    let end: Date?
    let venue: Venue
    /// Town this event is filed under, matching `AppLocation.town`.
    let town: String
    let state: USState
    let ticketURL: URL?
    let priceLabel: String?

    var coordinate: CLLocationCoordinate2D { venue.coordinate }

    var isFree: Bool {
        priceLabel?.localizedCaseInsensitiveContains("free") ?? false
    }

    /// Whether this event belongs to a given town. Town names are not unique
    /// across the two states — Manchester is both a Vermont and a New
    /// Hampshire town — so the state has to agree as well.
    func matches(_ location: AppLocation) -> Bool {
        town.localizedCaseInsensitiveCompare(location.town) == .orderedSame
            && state == location.state
    }
}

// MARK: - Date presentation

extension Event {
    /// "Fri, Aug 7" — the line under an event title in a card.
    var dayLabel: String {
        start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// "7:30 PM" or "7:30 PM – 10:00 PM" when an end time exists.
    var timeLabel: String {
        let startText = start.formatted(date: .omitted, time: .shortened)
        guard let end else { return startText }
        return "\(startText) – \(end.formatted(date: .omitted, time: .shortened))"
    }

    /// Full line used on the detail screen.
    var fullDateLabel: String {
        start.formatted(.dateTime.weekday(.wide).month(.wide).day()) + " · " + timeLabel
    }

    /// "Today" / "Tomorrow" / "In 3 days" — the relative badge on a card.
    var relativeLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(start) { return "Today" }
        if calendar.isDateInTomorrow(start) { return "Tomorrow" }
        let days = calendar.dateComponents([.day], from: .now, to: start).day ?? 0
        return days <= 7 ? start.formatted(.dateTime.weekday(.wide)) : "In \(days) days"
    }

    var isToday: Bool { Calendar.current.isDateInToday(start) }

    /// Distance in meters from an arbitrary point — used for "near me" sorting.
    func distance(from location: CLLocation) -> CLLocationDistance {
        venue.location.distance(from: location)
    }
}

// MARK: - Time bucketing

/// The section an event falls into on the Discover screen.
enum TimeBucket: String, CaseIterable, Identifiable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case thisWeek = "This Week"
    case later = "Later"

    var id: String { rawValue }

    static func bucket(for date: Date, calendar: Calendar = .current) -> TimeBucket {
        if calendar.isDateInToday(date) { return .today }
        if calendar.isDateInTomorrow(date) { return .tomorrow }
        let days = calendar.dateComponents([.day], from: .now, to: date).day ?? 0
        return days <= 7 ? .thisWeek : .later
    }
}
