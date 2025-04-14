//
//  SavedEventsView.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 04/10/25
//

import SwiftUI

/// Displays all events previously saved by the user using Core Data.
/// If no events are saved, a placeholder message is shown.
struct SavedEventsView: View {
    
    /// List of events fetched from Core Data
    @State private var savedEvents: [SavedEvent] = []

    var body: some View {
        VStack {
            // If no events saved, show empty state message
            if savedEvents.isEmpty {
                Text("No saved events yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // Show saved events in a list
                List(savedEvents, id: \.id) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        // Event title
                        Text(event.name ?? "Untitled Event")
                            .font(.headline)

                        // Event start time
                        Text(event.startTime ?? "Unknown time")
                            .font(.subheadline)

                        // Optional event description
                        if let desc = event.eventDescription {
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        // Show coordinates if they exist
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
            // Fetch saved events when view loads
            savedEvents = CoreDataManager.shared.fetchSavedEvents()
            print("📲 Reloaded saved events in UI: \(savedEvents.count) found")
        }
    }
}

