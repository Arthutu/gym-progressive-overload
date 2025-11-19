import SwiftUI
import SwiftData

@main
struct GymTrackerApp: App {
    let authManager = AuthenticationManager()
    let cloudKitManager = CloudKitManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            WorkoutSession.self,
            WorkoutSet.self
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
            ContentView(
                authManager: authManager,
                cloudKitManager: cloudKitManager
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
