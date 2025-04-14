


import CoreData
import Foundation
import MapKit

class CoreDataManager {
    static let shared = CoreDataManager()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "FBEventsMockProject") // match your .xcdatamodeld name
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Failed to load Core Data stack: \(error)")
            }
        }
    }

    // MARK: - Save Context
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

    func saveEvent(from event: FBEvent) {
        let context = container.viewContext
        let newEvent = SavedEvent(context: context)
        newEvent.name = event.name
        newEvent.eventDescription = event.description
        newEvent.latitude = event.coordinate?.latitude ?? 0
        newEvent.longitude = event.coordinate?.longitude ?? 0
        newEvent.startTime = event.start_time
        newEvent.endTime = event.end_time ?? ""
        newEvent.id = event.id

        do {
            try context.save()
            print("✅ Saved: \(event.name) - \(event.start_time)")
        } catch {
            print("❌ Failed to save event: \(error.localizedDescription)")
        }

        // Fetch after save to confirm it worked
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


    // MARK: - Fetch Saved Events
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

