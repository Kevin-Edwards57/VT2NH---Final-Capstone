//
//  EventViewModel.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 04/03/25
//

import Foundation
import CoreLocation

/// ViewModel responsible for fetching and filtering Facebook events.
/// Manages API calls, state updates, and location-based event filtering.
class EventViewModel: ObservableObject {
    
    /// Fetched list of Facebook events from the API
    @Published var events: [FBEvent] = []
    
    /// Loading state for API call
    @Published var isLoading: Bool = false
    
    /// Optional error message for display/debugging
    @Published var errorMessage: String? = nil

    /// Fetches event data from Facebook Graph API
    func fetchEvents() {
        isLoading = true
        errorMessage = nil

        // ⚠️ Replace with a secure method for storing tokens in production
        let urlStr = "https://graph.facebook.com/v19.0/578729015328010/events?access_token=REDACTED_FACEBOOK_TOKEN"

        guard let url = URL(string: urlStr) else {
            print("Invalid URL")
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }

        // API request to fetch event data
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            // Handle API error
            if let error = error {
                print("Request failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            // Handle empty data
            guard let data = data else {
                print("No data returned")
                DispatchQueue.main.async {
                    self.errorMessage = "No data returned"
                }
                return
            }

            // Decode the JSON response
            do {
                let response = try JSONDecoder().decode(FBEventResponse.self, from: data)
                DispatchQueue.main.async {
                    self.events = response.data
                    print("✅ Loaded \(response.data.count) events")
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    /// Filters events based on the selected AppLocation
    /// Matches either the event's town name or checks if the location is within 20km
    /// - Parameter location: The town to filter events for
    /// - Returns: Array of FBEvents that match or are nearby
    func filteredEvents(for location: AppLocation) -> [FBEvent] {
        events.filter { event in
            guard let place = event.place else { return false }

            // 1. Try matching town with event place name
            if place.name.localizedCaseInsensitiveContains(location.town) {
                return true
            }

            // 2. Check if event coordinates are within 20km of town
            if let lat = place.location?.latitude,
               let lon = place.location?.longitude {
                let eventLoc = CLLocation(latitude: lat, longitude: lon)
                let townLoc = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                return eventLoc.distance(from: townLoc) < 20000 // 20km radius
            }

            return false
        }
    }
}

