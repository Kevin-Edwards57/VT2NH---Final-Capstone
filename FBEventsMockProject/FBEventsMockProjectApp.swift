//
//  FBEventsMockProjectApp.swift
//  FBEventsMockProject
//
//  Created by Kevin Edwards on 4/11/25.
//

import SwiftUI

@main
struct FBEventsMockProjectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
