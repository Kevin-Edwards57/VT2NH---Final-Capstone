import Foundation
import CoreLocation

class EventViewModel: ObservableObject {
    @Published var events: [FBEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchEvents() {
        isLoading = true
        errorMessage = nil

        let urlStr = "https://graph.facebook.com/v19.0/578729015328010/events?access_token=REDACTED_FACEBOOK_TOKEN"

        guard let url = URL(string: urlStr) else {
            print("Invalid URL")
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error {
                print("Request failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let data = data else {
                print("No data returned")
                DispatchQueue.main.async {
                    self.errorMessage = "No data returned"
                }
                return
            }

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

    // ✅ Fix: Filter events by either town name or coordinates
    func filteredEvents(for location: AppLocation) -> [FBEvent] {
        events.filter { event in
            guard let place = event.place else { return false }

            // 1. Try matching town with place name
            if place.name.localizedCaseInsensitiveContains(location.town) {
                return true
            }

            // 2. Try matching coordinates if available
            if let lat = place.location?.latitude,
               let lon = place.location?.longitude {
                let eventLoc = CLLocation(latitude: lat, longitude: lon)
                let townLoc = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                return eventLoc.distance(from: townLoc) < 20000 // 20km
            }

            return false
        }
    }
}

