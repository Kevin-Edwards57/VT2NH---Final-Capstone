//
//  AppLocation.swift
//  VT2NH
//
//  The towns the app covers, and the state they sit in.
//

import Foundation
import CoreLocation

// MARK: - State

enum USState: String, Codable, CaseIterable, Identifiable, Sendable {
    case vermont = "Vermont"
    case newHampshire = "New Hampshire"

    var id: String { rawValue }

    /// "VT" / "NH" — used in compact labels and town names.
    var abbreviation: String {
        switch self {
        case .vermont: "VT"
        case .newHampshire: "NH"
        }
    }

    var tagline: String {
        switch self {
        case .vermont:      "Green Mountains, lake towns, and the smallest capital in the country."
        case .newHampshire: "White Mountains, the seacoast, and the lakes in between."
        }
    }

    /// Wikimedia Commons file used for the state's hero card. The Wikipedia
    /// article's own lead image is the state flag, which is not what we want.
    var heroCommonsFile: String {
        switch self {
        case .vermont:      "File:Green Mountains Panorama.jpg"
        case .newHampshire: "File:Autumn In New Hampshire (128325987).jpeg"
        }
    }

    var towns: [AppLocation] {
        LocationCatalog.towns.filter { $0.state == self }
    }
}

// MARK: - Town

/// A town VT2NH covers. Static data — coordinates come from each town's
/// Wikipedia article, so they are the official centroids rather than estimates.
struct AppLocation: Identifiable, Hashable, Sendable {
    let id: String
    let town: String
    let state: USState
    let latitude: Double
    let longitude: Double
    /// One line of context shown on the town chip and detail header.
    let blurb: String

    /// Exact Wikipedia article title. Several of these need disambiguation —
    /// "Barre, Vermont" is the town, "Barre (city), Vermont" is the city.
    let wikipediaTitle: String

    /// Commons file to use when Wikipedia's lead image is a locator map rather
    /// than a photograph, which is common for small unincorporated villages.
    let fallbackCommonsFile: String?

    /// "Burlington, VT"
    var name: String { "\(town), \(state.abbreviation)" }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// Canonical Wikipedia page for the town.
    var wikipediaURL: URL? {
        let slug = wikipediaTitle.replacingOccurrences(of: " ", with: "_")
        return URL(string: "https://en.wikipedia.org/wiki/\(slug)")
    }
}

// MARK: - Catalog

enum LocationCatalog {
    static let towns: [AppLocation] = [
        AppLocation(id: "burlington", town: "Burlington", state: .vermont,
                    latitude: 44.5064, longitude: -73.2431,
                    blurb: "Lakefront city with the busiest music calendar in the state.",
                    wikipediaTitle: "Burlington, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "montpelier", town: "Montpelier", state: .vermont,
                    latitude: 44.2597, longitude: -72.5647,
                    blurb: "The smallest state capital in the country.",
                    wikipediaTitle: "Montpelier, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "stowe", town: "Stowe", state: .vermont,
                    latitude: 44.5006, longitude: -72.7183,
                    blurb: "Mountain town — festivals in summer, skiing all winter.",
                    wikipediaTitle: "Stowe, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "northfield", town: "Northfield", state: .vermont,
                    latitude: 44.1236, longitude: -72.6903,
                    blurb: "Norwich University town in the Dog River valley.",
                    wikipediaTitle: "Northfield, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "barre", town: "Barre", state: .vermont,
                    latitude: 44.1981, longitude: -72.5017,
                    blurb: "Granite capital, with an opera house to match.",
                    wikipediaTitle: "Barre (city), Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "rutland", town: "Rutland", state: .vermont,
                    latitude: 43.6144, longitude: -72.9906,
                    blurb: "Southern Vermont's biggest downtown.",
                    wikipediaTitle: "Rutland (city), Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "wrj", town: "White River Junction", state: .vermont,
                    latitude: 43.65, longitude: -72.3289,
                    blurb: "Railroad village turned arts district.",
                    wikipediaTitle: "White River Junction, Vermont",
                    fallbackCommonsFile: "File:North Main Street, White River Junction, VT.jpg"),
        AppLocation(id: "middlebury", town: "Middlebury", state: .vermont,
                    latitude: 44.0044, longitude: -73.1222,
                    blurb: "College town on Otter Creek falls.",
                    wikipediaTitle: "Middlebury, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "brattleboro", town: "Brattleboro", state: .vermont,
                    latitude: 42.8708, longitude: -72.6144,
                    blurb: "Gallery walks, co-ops, and a strong independent streak.",
                    wikipediaTitle: "Brattleboro, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "bennington", town: "Bennington", state: .vermont,
                    latitude: 42.88, longitude: -73.2422,
                    blurb: "Covered bridges and a 306-foot battle monument.",
                    wikipediaTitle: "Bennington, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "woodstock", town: "Woodstock", state: .vermont,
                    latitude: 43.6069, longitude: -72.5472,
                    blurb: "Postcard village green ringed by Federal-era homes.",
                    wikipediaTitle: "Woodstock, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "stjohnsbury", town: "St. Johnsbury", state: .vermont,
                    latitude: 44.4867, longitude: -72.0111,
                    blurb: "Northeast Kingdom hub with a Victorian art gallery.",
                    wikipediaTitle: "St. Johnsbury, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "winooski", town: "Winooski", state: .vermont,
                    latitude: 44.4981, longitude: -73.1856,
                    blurb: "Dense mill-town downtown across the river from Burlington.",
                    wikipediaTitle: "Winooski, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "shelburne", town: "Shelburne", state: .vermont,
                    latitude: 44.3814, longitude: -73.2422,
                    blurb: "Lakeside town south of Burlington, home to the museum.",
                    wikipediaTitle: "Shelburne, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "waterbury", town: "Waterbury", state: .vermont,
                    latitude: 44.3853, longitude: -72.7556,
                    blurb: "Brewery and cider country at the base of the notch.",
                    wikipediaTitle: "Waterbury, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "manchestervt", town: "Manchester", state: .vermont,
                    latitude: 43.1422, longitude: -73.0856,
                    blurb: "Marble sidewalks, outlet shops, and Equinox trailheads.",
                    wikipediaTitle: "Manchester, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "lebanon", town: "Lebanon", state: .newHampshire,
                    latitude: 43.6353, longitude: -72.2531,
                    blurb: "Upper Valley hub around a classic town green.",
                    wikipediaTitle: "Lebanon, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "hanover", town: "Hanover", state: .newHampshire,
                    latitude: 43.7156, longitude: -72.1911,
                    blurb: "Home of Dartmouth and its year-round arts programming.",
                    wikipediaTitle: "Hanover, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "concord", town: "Concord", state: .newHampshire,
                    latitude: 43.2067, longitude: -71.5381,
                    blurb: "State capital with a gold dome and a walkable Main Street.",
                    wikipediaTitle: "Concord, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "manchesternh", town: "Manchester", state: .newHampshire,
                    latitude: 42.9908, longitude: -71.4636,
                    blurb: "New Hampshire's largest city, built on the Amoskeag mills.",
                    wikipediaTitle: "Manchester, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "nashua", town: "Nashua", state: .newHampshire,
                    latitude: 42.7575, longitude: -71.4644,
                    blurb: "Riverfront downtown on the Massachusetts line.",
                    wikipediaTitle: "Nashua, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "portsmouth", town: "Portsmouth", state: .newHampshire,
                    latitude: 43.0581, longitude: -70.7825,
                    blurb: "Colonial seaport with the state's densest food and music scene.",
                    wikipediaTitle: "Portsmouth, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "keene", town: "Keene", state: .newHampshire,
                    latitude: 42.9494, longitude: -72.2997,
                    blurb: "Wide Main Street in the heart of the Monadnock region.",
                    wikipediaTitle: "Keene, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "dover", town: "Dover", state: .newHampshire,
                    latitude: 43.1889, longitude: -70.8736,
                    blurb: "Cocheco mill city with a fast-growing downtown.",
                    wikipediaTitle: "Dover, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "exeter", town: "Exeter", state: .newHampshire,
                    latitude: 42.9817, longitude: -70.9478,
                    blurb: "Revolutionary-era town on the Squamscott.",
                    wikipediaTitle: "Exeter, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "laconia", town: "Laconia", state: .newHampshire,
                    latitude: 43.5725, longitude: -71.4775,
                    blurb: "Lakes Region gateway on Winnipesaukee's western shore.",
                    wikipediaTitle: "Laconia, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "northconway", town: "North Conway", state: .newHampshire,
                    latitude: 44.0536, longitude: -71.1283,
                    blurb: "White Mountains basecamp with a scenic railroad.",
                    wikipediaTitle: "North Conway, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "littleton", town: "Littleton", state: .newHampshire,
                    latitude: 44.3322, longitude: -71.8097,
                    blurb: "Main Street on the Ammonoosuc, north-country friendly.",
                    wikipediaTitle: "Littleton, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "peterborough", town: "Peterborough", state: .newHampshire,
                    latitude: 42.8706, longitude: -71.9517,
                    blurb: "Small town with an outsized arts and literary tradition.",
                    wikipediaTitle: "Peterborough, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "plymouth", town: "Plymouth", state: .newHampshire,
                    latitude: 43.7439, longitude: -71.7222,
                    blurb: "University town where the Pemigewasset meets the Baker.",
                    wikipediaTitle: "Plymouth, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "wolfeboro", town: "Wolfeboro", state: .newHampshire,
                    latitude: 43.6147, longitude: -71.1733,
                    blurb: "Calls itself America's oldest summer resort.",
                    wikipediaTitle: "Wolfeboro, New Hampshire",
                    fallbackCommonsFile: nil)
    ]

    /// The catalog town an event is filed under, matched on name *and* state.
    static func town(for event: Event) -> AppLocation? {
        towns.first { event.matches($0) }
    }

    static func town(named town: String) -> AppLocation? {
        towns.first { $0.town.localizedCaseInsensitiveCompare(town) == .orderedSame }
    }
}
