//
//  LocationListView.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 2025-04-14
//

import SwiftUI

/// Displays a list of towns from the `LocationList` model.
/// When a user taps on a town, the view calls `onLocationSelect` with the selected location.
/// This allows parent views to control navigation or behavior when a town is selected.
struct LocationListView: View {
    
    /// Closure triggered when a location is selected (used for navigation or state updates)
    var onLocationSelect: ((AppLocation) -> Void)? = nil

    var body: some View {
        List(LocationList.towns) { location in
            Button {
                // Trigger parent action with selected location
                onLocationSelect?(location)
            } label: {
                VStack(alignment: .leading) {
                    Text(location.name)
                        .font(.headline)
                    Text("Tap to view events")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Browse Locations")
    }
}

