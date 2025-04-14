import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

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
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FBEventsMockProject")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}

