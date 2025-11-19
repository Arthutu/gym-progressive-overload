import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var authManager: AuthenticationManager
    @State private var cloudKitManager: CloudKitManager
    @State private var selectedTab = 0

    init(authManager: AuthenticationManager, cloudKitManager: CloudKitManager) {
        _authManager = State(initialValue: authManager)
        _cloudKitManager = State(initialValue: cloudKitManager)
    }

    var body: some View {
        Group {
            if authManager.isAuthenticated, let user = authManager.currentUser {
                MainTabView(
                    user: user,
                    authManager: authManager,
                    cloudKitManager: cloudKitManager
                )
            } else {
                LoginView(authManager: authManager)
            }
        }
        .onAppear {
            authManager.configure(modelContext: modelContext)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    let user: User
    let authManager: AuthenticationManager
    let cloudKitManager: CloudKitManager

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutListView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)

            PublicWorkoutFeedView(cloudKitManager: cloudKitManager)
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                .tag(2)

            ProfileView(
                user: user,
                authManager: authManager,
                cloudKitManager: cloudKitManager
            )
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
            .tag(3)
        }
    }
}
