//
//  EventAnnotationView.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 03/31/2025
//

import SwiftUI
import MapKit

/// A custom annotation view used for displaying event markers on the map.
/// Shows a red pin icon with the event name underneath.
struct EventAnnotationView: View {
    
    /// The name of the event to display under the map pin
    let eventName: String

    var body: some View {
        VStack(spacing: 4) {
            
            // Red map pin icon
            Image(systemName: "mappin.and.ellipse")
                .font(.title)
                .foregroundColor(.red)
            
            // Event name label
            Text(eventName)
                .font(.caption)
                .fixedSize() // Prevents text from wrapping or shrinking
        }
    }
}

