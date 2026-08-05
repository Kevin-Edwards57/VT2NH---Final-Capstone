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
}

// MARK: - Town

/// A town VT2NH covers. Static data — there are ten of them and they do not change.
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
                    latitude: 44.4759, longitude: -73.2121,
                    blurb: "Lakefront city with the busiest music calendar in the state.",
                    wikipediaTitle: "Burlington, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "montpelier", town: "Montpelier", state: .vermont,
                    latitude: 44.2601, longitude: -72.5754,
                    blurb: "The smallest state capital in the country.",
                    wikipediaTitle: "Montpelier, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "stowe", town: "Stowe", state: .vermont,
                    latitude: 44.4654, longitude: -72.6874,
                    blurb: "Mountain town — festivals in summer, skiing all winter.",
                    wikipediaTitle: "Stowe, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "lebanon", town: "Lebanon", state: .newHampshire,
                    latitude: 43.6423, longitude: -72.2524,
                    blurb: "Upper Valley hub around a classic town green.",
                    wikipediaTitle: "Lebanon, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "hanover", town: "Hanover", state: .newHampshire,
                    latitude: 43.7022, longitude: -72.2896,
                    blurb: "Home of Dartmouth and its year-round arts programming.",
                    wikipediaTitle: "Hanover, New Hampshire",
                    fallbackCommonsFile: nil),
        AppLocation(id: "northfield", town: "Northfield", state: .vermont,
                    latitude: 44.1534, longitude: -72.6584,
                    blurb: "Norwich University town in the Dog River valley.",
                    wikipediaTitle: "Northfield, Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "barre", town: "Barre", state: .vermont,
                    latitude: 44.1970, longitude: -72.5020,
                    blurb: "Granite capital, with an opera house to match.",
                    wikipediaTitle: "Barre (city), Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "rutland", town: "Rutland", state: .vermont,
                    latitude: 43.6106, longitude: -72.9726,
                    blurb: "Southern Vermont's biggest downtown.",
                    wikipediaTitle: "Rutland (city), Vermont",
                    fallbackCommonsFile: nil),
        AppLocation(id: "wrj", town: "White River Junction", state: .vermont,
                    latitude: 43.6484, longitude: -72.3195,
                    blurb: "Railroad village turned arts district.",
                    wikipediaTitle: "White River Junction, Vermont",
                    fallbackCommonsFile: "File:North Main Street, White River Junction, VT.jpg"),
        AppLocation(id: "middlebury", town: "Middlebury", state: .vermont,
                    latitude: 44.0153, longitude: -73.1673,
                    blurb: "College town on Otter Creek falls.",
                    wikipediaTitle: "Middlebury, Vermont",
                    fallbackCommonsFile: nil)
    ]

    static func town(named town: String) -> AppLocation? {
        towns.first { $0.town.localizedCaseInsensitiveCompare(town) == .orderedSame }
    }
}
