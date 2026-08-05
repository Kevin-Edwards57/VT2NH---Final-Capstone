//
//  EventMapScreen.swift
//  VT2NH
//
//  Every filtered event as a pin, tinted by category. Tapping a pin raises a
//  compact card that pushes through to the full detail screen.
//

import SwiftUI
import MapKit

struct EventMapScreen: View {
    @Bindable var store: EventStore

    @State private var camera: MapCameraPosition = .region(Self.regionWide)
    @State private var selectedEvent: Event?

    /// Frames Vermont and New Hampshire together.
    private static let regionWide = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.95, longitude: -72.45),
        span: MKCoordinateSpan(latitudeDelta: 2.6, longitudeDelta: 2.6)
    )

    var body: some View {
        NavigationStack {
            Map(position: $camera, selection: $selectedEvent) {
                ForEach(store.filteredEvents) { event in
                    Marker(event.name, systemImage: event.category.symbol,
                           coordinate: event.coordinate)
                        .tint(Theme.tint(for: event.category))
                        .tag(event)
                }

                UserAnnotation()
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .safeAreaInset(edge: .top) {
                FilterBar(store: store)
                    .padding(.vertical, 8)
                    .background(.bar)
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedEvent {
                    NavigationLink(value: selectedEvent) {
                        EventCard(event: selectedEvent)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: selectedEvent)
            // Scoping Discover to a town filters these pins too. Without this
            // the camera stays framed on both states and the remaining pins sit
            // in one corner of an otherwise empty map.
            .onChange(of: store.selectedTown) { _, town in
                withAnimation(.snappy) {
                    camera = town.map {
                        .region(MKCoordinateRegion(
                            center: $0.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
                        ))
                    } ?? .region(Self.regionWide)
                }
                selectedEvent = nil
            }
            .navigationTitle(store.selectedTown?.town ?? "Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fit all", systemImage: "arrow.up.left.and.arrow.down.right") {
                        withAnimation { camera = .region(regionForVisibleEvents()) }
                    }
                }
            }
            .overlay {
                if store.filteredEvents.isEmpty {
                    ContentUnavailableView("No events on the map",
                                           systemImage: "mappin.slash",
                                           description: Text("Adjust your filters to see pins."))
                        .background(.thinMaterial)
                }
            }
        }
    }

    /// A region that contains every currently visible pin, with padding.
    private func regionForVisibleEvents() -> MKCoordinateRegion {
        let coordinates = store.filteredEvents.map(\.coordinate)
        guard !coordinates.isEmpty else { return Self.regionWide }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max()
        else { return Self.regionWide }

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                           longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: max(maxLat - minLat, 0.05) * 1.4,
                                   longitudeDelta: max(maxLon - minLon, 0.05) * 1.4)
        )
    }
}
