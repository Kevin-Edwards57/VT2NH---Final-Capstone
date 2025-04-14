//
//  LocationExplorerView.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 04/02/25
//

import SwiftUI
import MapKit

/// Enum used to toggle between List and Map view
enum ViewType: String, CaseIterable {
    case list = "List"
    case map = "Map"
}

/// Displays a dynamic view of Facebook events near a selected location.
/// Users can toggle between a list of events or a map showing event locations.
struct LocationExplorerView: View {
    
    /// The selected location to browse events for
    let location: AppLocation
    
    /// Determines whether the screen launches in map or list view
    let startInMapMode: Bool

    /// ViewModel responsible for fetching and filtering events
    @StateObject private var viewModel = EventViewModel()
    
    /// Current tab selection (list or map)
    @State private var selectedView: ViewType
    
    /// Optional selected event for detail sheet presentation
    @State private var selectedEvent: FBEvent? = nil
    
    /// Map position to control initial region and camera
    @State private var cameraPosition: MapCameraPosition

    /// Custom initializer to allow map-first view if needed
    init(location: AppLocation, startInMapMode: Bool = false) {
        self.location = location
        self.startInMapMode = startInMapMode
        _selectedView = State(initialValue: startInMapMode ? .map : .list)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        ))
    }

    var body: some View {
        VStack {
            
            // 📍 Header
            Text("FB Events")
                .font(.title)
                .bold()
                .padding(.top, 4)

            // 🔁 Link to return to main view
            NavigationLink("Browse All Locations") {
                ContentView()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.top, 4)

            // 📌 Current Town Label
            Text("\(location.town), \(location.state)")
                .font(.title2)
                .fontWeight(.semibold)

            // 🧮 Event Count
            Text("Events near \(location.town): \(viewModel.filteredEvents(for: location).count)")
                .font(.subheadline)
                .foregroundColor(.gray)

            // 🧭 Toggle between List and Map
            Picker("View", selection: $selectedView) {
                ForEach(ViewType.allCases, id: \.self) { view in
                    Text(view.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // 📋 List View of Events
            if selectedView == .list {
                List(viewModel.filteredEvents(for: location)) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.name)
                            .font(.headline)
                        Text(event.formattedDate)
                            .font(.subheadline)
                        
                        if let venue = event.place?.name {
                            Text(venue)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let desc = event.description {
                            Text(desc)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        selectedEvent = event
                    }
                }
                .listStyle(.inset)
                .sheet(item: $selectedEvent) { event in
                    EventDetailSheet(event: event)
                }
            } else {
                // 🗺️ Map View of Events
                EventMapView(
                    events: viewModel.filteredEvents(for: location),
                    location: location,
                    position: $cameraPosition
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            viewModel.fetchEvents()
        }
        .navigationTitle(location.town)
        .navigationBarTitleDisplayMode(.inline)
    }
}

