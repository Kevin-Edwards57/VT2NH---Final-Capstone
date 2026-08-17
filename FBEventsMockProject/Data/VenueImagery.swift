//
//  VenueImagery.swift
//  VT2NH
//
//  Hand-verified Wikimedia Commons photographs for specific venues.
//
//  Two automated approaches were tried and rejected before this list:
//
//    * Name search against Commons returned a recreation area in England for
//      Stowe's path and a park in Australia for Concord's White Park.
//    * Geosearch around the venue coordinates was far more accurate but only
//      yielded a usable photo for 6 of 105 venues, and still drifted — the
//      Brattleboro museum resolved to a nearby oil-change shop.
//
//  So this list is deliberately short and checked by hand. Anything absent
//  falls back to the event's town photo, which is verified per town and always
//  relevant. Coverage matters less than never showing the wrong place.
//

import Foundation

enum VenueImagery {

    /// Venue name exactly as it appears in the feed -> Commons file title.
    private static let files: [String: String] = [
        "Flynn Center for the Performing Arts":
            "File:Flynn Theatre marquee Burlington Vermont.jpg",
        "Church Street Marketplace":
            "File:Church Street Marketplace Burlington Vermont looking north from Main Street.jpg",
        "Waterfront Park":
            "File:Burlington Discover Jazz Festival Waterfront Park Burlington VT June 2025 32.jpg",
        "Barre Opera House":
            "File:Barre City Hall and Opera House, Vermont.jpg",
        "New Hampshire State House":
            "File:Concord New Hampshire state house 20041229.jpg",
        "Palace Theatre":
            "File:Palace Theatre, Manchester NH.jpg",
        "Weirs Beach Boardwalk":
            "File:Weirs Beach sign Laconia NH.JPG",
        "Hopkins Center for the Arts":
            "File:Dartmouth College campus 2007-06-23 Hopkins Center for the Arts 02.JPG",
        "The Colonial Theatre":
            "File:The Colonial Theatre 95 Main Street Keene NH September 2024.jpg",
        "Bennington Battle Monument":
            "File:Bennington Battle Monument October 2021 001.jpg"
    ]

    static func commonsFile(for venueName: String) -> String? {
        files[venueName]
    }
}
