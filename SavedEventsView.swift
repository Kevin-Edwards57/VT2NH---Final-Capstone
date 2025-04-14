import SwiftUI

struct SavedEventsView: View {
    @State private var savedEvents: [SavedEvent] = []

    var body: some View {
        VStack {
            if savedEvents.isEmpty {
                Text("No saved events yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(savedEvents, id: \.id) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.name ?? "Untitled Event")
                            .font(.headline)

                        Text(event.startTime ?? "Unknown time")
                            .font(.subheadline)

                        if let desc = event.eventDescription {
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        if event.latitude != 0 && event.longitude != 0 {
                            Text("📍 Lat: \(event.latitude), Lon: \(event.longitude)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Saved Events")
        .onAppear {
            savedEvents = CoreDataManager.shared.fetchSavedEvents()
            print("📲 Reloaded saved events in UI: \(savedEvents.count) found")
        }
    }
}

