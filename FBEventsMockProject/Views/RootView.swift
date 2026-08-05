//
//  RootView.swift
//  VT2NH
//
//  Three tabs. The store is created once here and shared, so Discover and Map
//  always agree on the active filters.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var store = EventStore()
    @State private var locationProvider = LocationProvider()
    @Query private var savedEvents: [SavedEvent]

    var body: some View {
        TabView {
            Tab("Discover", systemImage: "sparkle.magnifyingglass") {
                DiscoverView(store: store, locationProvider: locationProvider)
            }

            Tab("Towns", systemImage: "building.2.fill") {
                TownsView(store: store)
            }

            Tab("Map", systemImage: "map.fill") {
                EventMapScreen(store: store)
            }

            Tab("Saved", systemImage: "heart.fill") {
                SavedEventsView()
            }
            .badge(savedEvents.count)
        }
        .task {
            // Only load once; pull-to-refresh handles the rest.
            if store.events.isEmpty { await store.load() }
        }
    }
}
