//
//  ContentView.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 03/28/25
//

import SwiftUI
import MapKit

/// Main landing screen for VT2NH app.
/// Displays the project logo, title, description, and a list of towns across Vermont and New Hampshire.
/// Users can also access their saved events via the "View Saved Events" button.
struct ContentView: View {
    
    /// ViewModel responsible for managing fetched events (not used directly here, but kept ready for future expansion)
    @StateObject private var viewModel = EventViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // App Header
                Text("Browse Locations")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // App Logo
                Image("DiscoverIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)

                // App Title
                Text("VT2NH")
                    .font(.title)
                    .fontWeight(.bold)

                // Tagline
                Text("Find events by town across Vermont and New Hampshire")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // 🔖 View Saved Events Button
                NavigationLink(destination: SavedEventsView()) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("View Saved Events")
                            .font(.subheadline)
                    }
                    .foregroundColor(.red)
                    .padding(.vertical, 6)
                }

                // 🗺️ List of Towns
                List(LocationList.towns) { location in
                    NavigationLink(destination: LocationDetailView(location: location)) {
                        VStack(alignment: .leading) {
                            Text(location.name)
                                .font(.headline)
                            Text("Tap to view more")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding(.top)
        }
    }
}

