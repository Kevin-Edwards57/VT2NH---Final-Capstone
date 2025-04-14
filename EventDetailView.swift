import SwiftUI
import MapKit

// Marker helper
struct EventLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct EventDetailSheet: View {
    var event: FBEvent
    @State private var isSaved = false
    @State private var showSaveAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.name)
                    .font(.title)
                    .fontWeight(.bold)

                if let description = event.description {
                    Text(description)
                        .font(.body)
                }

                if let coords = event.coordinate {
                    Text("Map Preview")
                        .font(.headline)

                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coords,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) {
                        Marker(event.name, coordinate: coords)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)

                    Button {
                        let urlString = "http://maps.apple.com/?daddr=\(coords.latitude),\(coords.longitude)&dirflg=d"
                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Get Directions", systemImage: "car.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                // 🔥 Save Event Button with debug print
                Button {
                    print("🔥 Save button tapped for event: \(event.name)")
                    CoreDataManager.shared.saveEvent(from: event)
                    isSaved = true
                    showSaveAlert = true
                } label: {
                    Label(isSaved ? "Saved!" : "Save Event", systemImage: isSaved ? "checkmark.circle.fill" : "heart.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSaved ? Color.gray : Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isSaved)
                .alert("Event Saved ✅", isPresented: $showSaveAlert) {
                    Button("OK", role: .cancel) { }
                }

                if let urlString = event.eventURL ?? hardcodedLink(for: event.name),
                   let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("Visit Event Website", systemImage: "link.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func hardcodedLink(for name: String) -> String? {
        if name.localizedCaseInsensitiveContains("Wedding Show") {
            return "https://www.eventbrite.com/e/burlington-vt-wedding-show-tickets-851742112587"
        } else if name.localizedCaseInsensitiveContains("Sonido MalMaiz") {
            return "https://www.artsriot.com/event-details/sonidomalmaiz-kotokobrass-apr12"
        } else if name.localizedCaseInsensitiveContains("Electrify Vermont") {
            return "https://www.eventbrite.com/e/electrify-vermont-summit-tickets-1144831825809"
        } else if name.localizedCaseInsensitiveContains("Spring Flow Yoga") {
            return "https://www.sprucepeak.com/explore/events-calendar/"
        } else if name.localizedCaseInsensitiveContains("MudFest") {
            return "https://allevents.in/montpelier/april"
        } else if name.localizedCaseInsensitiveContains("Improv Comedy Night") {
            return "https://www.mpa-hub.org/events"
        } else if name.localizedCaseInsensitiveContains("Gusto's Glow Party") {
            return "https://www.eventbrite.com/e/gustos-glow-party-tickets-1262905096139?aff=ebdssbdestsearch"
        } else if name.localizedCaseInsensitiveContains("Easter Egg Hunt") {
            return "https://www.eventbrite.com/e/easter-egg-hunt-tickets-1313354341189?aff=ehometext"
        }
        return nil
    }
}

