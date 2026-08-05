//
//  SavedEvent.swift
//  VT2NH
//
//  SwiftData record for an event the user bookmarked. Replaces the old
//  Core Data stack — same job, without the container/context boilerplate.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class SavedEvent {
    /// Matches `Event.id`. Unique so tapping Save twice can never duplicate a row.
    @Attribute(.unique) var eventID: String
    var name: String
    var summary: String
    var categoryRaw: String
    var start: Date
    var end: Date?
    var venueName: String
    var venueAddress: String?
    var latitude: Double
    var longitude: Double
    var town: String
    var stateRaw: String
    var ticketURLString: String?
    var priceLabel: String?
    var imageURLString: String?
    var savedAt: Date

    init(event: Event, savedAt: Date = .now) {
        self.eventID = event.id
        self.name = event.name
        self.summary = event.summary
        self.categoryRaw = event.category.rawValue
        self.start = event.start
        self.end = event.end
        self.venueName = event.venue.name
        self.venueAddress = event.venue.address
        self.latitude = event.venue.latitude
        self.longitude = event.venue.longitude
        self.town = event.town
        self.stateRaw = event.state.rawValue
        self.ticketURLString = event.ticketURL?.absoluteString
        self.priceLabel = event.priceLabel
        self.imageURLString = event.imageURL?.absoluteString
        self.savedAt = savedAt
    }

    var category: EventCategory { EventCategory(rawValue: categoryRaw) ?? .community }
    var state: USState { USState(rawValue: stateRaw) ?? .vermont }
    var ticketURL: URL? { ticketURLString.flatMap(URL.init(string:)) }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Whether the event has already happened — drives the "Past" styling in Saved.
    var hasPassed: Bool { (end ?? start) < .now }

    /// Round-trips back into the domain model so saved rows reuse the same detail screen.
    var asEvent: Event {
        Event(id: eventID,
              name: name,
              summary: summary,
              category: category,
              start: start,
              end: end,
              venue: Venue(name: venueName, address: venueAddress,
                           latitude: latitude, longitude: longitude),
              town: town,
              state: state,
              ticketURL: ticketURL,
              priceLabel: priceLabel,
              imageURL: imageURLString.flatMap(URL.init(string:)))
    }
}
