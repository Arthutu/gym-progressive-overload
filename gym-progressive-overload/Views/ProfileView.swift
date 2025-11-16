import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var user: User
    @State private var authManager: AuthenticationManager
    @State private var cloudKitManager: CloudKitManager
    @State private var showingSignOutAlert = false

    init(user: User, authManager: AuthenticationManager, cloudKitManager: CloudKitManager) {
        _user = Bindable(user)
        _authManager = State(initialValue: authManager)
        _cloudKitManager = State(initialValue: cloudKitManager)
    }

    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.gradient)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.title2.bold())

                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text("Member since \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Privacy Settings
                Section("Privacy Settings") {
                    Toggle("Public Profile", isOn: $user.profileIsPublic)
                        .onChange(of: user.profileIsPublic) {
                            saveSettings()
                        }

                    Toggle("Public Workouts", isOn: $user.workoutsArePublic)
                        .onChange(of: user.workoutsArePublic) {
                            saveSettings()
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy Info")
                            .font(.caption.bold())

                        if user.profileIsPublic {
                            Text("• Your profile is visible to other users")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("• Your profile is private")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if user.workoutsArePublic {
                            Text("• Your workouts appear in the public feed")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("• Your workouts are private")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Sync Section
                Section("Cloud Sync") {
                    HStack {
                        Label("Last Synced", systemImage: "cloud")

                        Spacer()

                        if let lastSync = user.lastSyncedAt {
                            Text(lastSync, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Never")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(action: syncNow) {
                        HStack {
                            if cloudKitManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }

                            Text(cloudKitManager.isSyncing ? "Syncing..." : "Sync Now")
                        }
                    }
                    .disabled(cloudKitManager.isSyncing)

                    if let syncError = cloudKitManager.syncError {
                        Text(syncError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // Account Section
                Section {
                    Button(role: .destructive, action: { showingSignOutAlert = true }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? Your data will remain synced in iCloud.")
            }
        }
    }

    private func saveSettings() {
        try? modelContext.save()

        // Sync updated settings to CloudKit
        Task {
            try? await cloudKitManager.saveUser(user)
        }
    }

    private func syncNow() {
        Task {
            try? await cloudKitManager.syncAllData(for: user, modelContext: modelContext)
        }
    }
}
