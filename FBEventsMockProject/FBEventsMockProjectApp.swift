//
//  FBEventsMockProjectApp.swift
//  VT2NH
//
//  Entry point. Installs the SwiftData container and hands off to RootView.
//

import SwiftUI
import SwiftData

@main
struct VT2NHApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: SavedEvent.self)
    }
}
