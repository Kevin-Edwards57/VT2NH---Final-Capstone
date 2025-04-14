//
//  FacebookEventModel.swift
//  FBEventsMockProject
//
//  Created by Kevin Edwards on 4/11/25.
//

import Foundation
import MapKit

struct FBEventResponse: Codable {
    let data: [FBEvent]
}

struct FBEvent: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let start_time: String
    let end_time: String?
    let place: Place?

    // 🗓️ Convert start_time to readable format
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: start_time) {
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return start_time
    }

    // 📍 Coordinate for Map display
    var coordinate: CLLocationCoordinate2D? {
        if let lat = place?.location?.latitude,
           let lon = place?.location?.longitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return nil
    }

    // 🔗 Optional external URL (mapped manually by event name)
    var eventURL: String? {
        if name.localizedCaseInsensitiveContains("Wedding Show") {
            return "https://www.eventbrite.com/e/burlington-vt-wedding-show-tickets-851742112587"
        } else if name.localizedCaseInsensitiveContains("Sonido MalMaiz") {
            return "https://www.artsriot.com/event-details/sonidomalmaiz-kotokobrass-apr12"
        } else if name.localizedCaseInsensitiveContains("Electrify Vermont Summit") {
            return "https://www.eventbrite.com/e/electrify-vermont-summit-tickets-1144831825809"
        } else if name.localizedCaseInsensitiveContains("Spring Flow Yoga") {
            return "https://www.sprucepeak.com/explore/events-calendar/"
        } else if name.localizedCaseInsensitiveContains("MudFest") {
            return "https://allevents.in/montpelier/april"
        } else if name.localizedCaseInsensitiveContains("Improv Comedy Night") {
            return "https://www.mpa-hub.org/events"
        }
        return nil
    }
}

struct Place: Codable {
    let name: String
    let location: Location?
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}
