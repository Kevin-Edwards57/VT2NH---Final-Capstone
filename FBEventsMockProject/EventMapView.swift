//
//  EventMapView.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 2025-04-14
//

import SwiftUI
import MapKit

/// Displays a map with markers for a list of events around a given location.
/// This view uses SwiftUI’s Map and Marker components (iOS 17+ compatible).
struct EventMapView: View {
    
    /// Array of Facebook events to display
    var events: [FBEvent]
    
    /// The currently selected location to center around
    var location: AppLocation
    
    /// The current camera position (can be updated externally)
    @Binding var position: MapCameraPosition

    var body: some View {
        VStack {
            // Main map view showing event markers
            Map(position: $position) {
                
                // Filter and show only events that have valid coordinates
                ForEach(events.compactMap { $0.coordinate != nil ? $0 : nil }, id: \.id) { event in
                    if let coord = event.coordinate {
                        Marker(event.name, coordinate: coord)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
    }
}

