//
//  PersistenceController.swift
//  VT2NH Capstone Project
//
//  Created by Kevin Edwards on 04/11/25
//

import CoreData

/// Manages the Core Data stack for the application, including a shared persistent container
/// and a preview mode for SwiftUI Previews using in-memory storage.
struct PersistenceController {
    
    /// Singleton instance of the controller for use across the app
    static let shared = PersistenceController()

    /// In-memory preview instance used for SwiftUI previews with dummy data
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Preload 10 fake events for Xcode previews
        for i in 0..<10 {
            let newEvent = SavedEvent(context: viewContext)
            newEvent.id = UUID().uuidString
            newEvent.name = "Sample Event \(i + 1)"
            newEvent.eventDescription = "This is a preview event description."
            newEvent.latitude = 44.4759
            newEvent.longitude = -73.2121
            newEvent.startTime = ISO8601DateFormatter().string(from: Date())
            newEvent.eventURL = "https://example.com"
            newEvent.placeName = "Preview Place"
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("❌ Failed to save preview context: \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    /// The NSPersistentContainer used for Core Data operations
    let container: NSPersistentContainer

    /// Initializes the persistence controller
    /// - Parameter inMemory: If true, stores data in RAM only (used for previews/tests)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FBEventsMockProject") // matches .xcdatamodeld

        if inMemory {
            // Store in RAM instead of disk for preview/testing purposes
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Load the persistent store
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("❌ Failed to load Core Data store: \(error), \(error.userInfo)")
            }
        }
    }
}

