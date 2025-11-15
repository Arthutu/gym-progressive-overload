//
//  gym_progressive_overloadApp.swift
//  gym-progressive-overload
//
//  Created by Arthur Rodolfo on 2025-11-15.
//

import SwiftUI
import SwiftData

@main
struct gym_progressive_overloadApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
