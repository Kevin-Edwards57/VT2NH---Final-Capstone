// Kevin Edwards
// CoreDataManager file
// Manages the CoreData

//  Created by Kevin Edwards on 04/07/25

import CoreData
import Foundation
import MapKit

/// Manages all Core Data operations for the app
class CoreDataManager {
    
    /// Singleton instance for global access
    static let shared = CoreDataManager()
    
    /// Persistent container tied to the Core Data model
    let container: NSPersistentContainer

    /// Initializes the Core Data stack
    private init() {
        // Make sure the name matches your .xcdatamodeld file
        container = NSPersistentContainer(name: "FBEventsMockProject")
        
        // Load the persistent store (SQLite database)
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Failed to load Core Data stack: \(error)")
            }
        }
    }

    // MARK: - Save Context
    
    /// Saves changes in the managed object context
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data save successful")
            } catch {
                print("❌ Failed to save context: \(error)")
            }
        }
    }

    /// Saves an FBEvent to Core Data
    /// - Parameter event: The FBEvent model to persist
    func saveEvent(from event: FBEvent) {
        let context = container.viewContext
        
        // Create a new Core Data object
        let newEvent = SavedEvent(context: context)
        newEvent.name = event.name
        newEvent.eventDescription = event.description
        newEvent.latitude = event.coordinate?.latitude ?? 0
        newEvent.longitude = event.coordinate?.longitude ?? 0
        newEvent.startTime = event.start_time
        newEvent.endTime = event.end_time ?? ""
        newEvent.id = event.id

        // Attempt to save to Core Data
        do {
            try context.save()
            print("✅ Saved: \(event.name) - \(event.start_time)")
        } catch {
            print("❌ Failed to save event: \(error.localizedDescription)")
        }

        // Optional: Fetch immediately to confirm
        let fetchRequest: NSFetchRequest<SavedEvent> = SavedEvent.fetchRequest()
        do {
            let saved = try context.fetch(fetchRequest)
            print("📦 Total saved events in DB: \(saved.count)")
            for e in saved {
                print("📝 \(e.name ?? "Unknown") — \(e.startTime ?? "")")
            }
        } catch {
            print("❌ Fetch error after save: \(error)")
        }
    }

    // MARK: - Fetch

    /// Fetches all saved events from Core Data
    /// - Returns: Array of SavedEvent objects
    func fetchSavedEvents() -> [SavedEvent] {
        let request: NSFetchRequest<SavedEvent> = SavedEvent.fetchRequest()
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch saved events: \(error)")
            return []
        }
    }
}

