import SwiftUI

struct PublicWorkoutFeedView: View {
    @State private var cloudKitManager: CloudKitManager
    @State private var publicWorkouts: [WorkoutSession] = []
    @State private var isLoading = false
    @State private var error: String?

    init(cloudKitManager: CloudKitManager) {
        _cloudKitManager = State(initialValue: cloudKitManager)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    SwiftUI.ProgressView("Loading public workouts...")
                } else if let error = error {
                    ContentUnavailableView(
                        "Unable to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if publicWorkouts.isEmpty {
                    ContentUnavailableView(
                        "No Public Workouts",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Be the first to share your workout!")
                    )
                } else {
                    List(publicWorkouts) { workout in
                        WorkoutCardView(workout: workout)
                    }
                    .refreshable {
                        await loadPublicWorkouts()
                    }
                }
            }
            .navigationTitle("Community Workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await loadPublicWorkouts()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task {
            await loadPublicWorkouts()
        }
    }

    private func loadPublicWorkouts() async {
        isLoading = true
        error = nil

        do {
            publicWorkouts = try await cloudKitManager.fetchPublicWorkouts(limit: 50)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct WorkoutCardView: View {
    let workout: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)

                VStack(alignment: .leading, spacing: 2) {
                    Text("User") // In the future, fetch user name from userID
                        .font(.headline)

                    Text(workout.startTime, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if workout.endTime != nil {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(formatDuration(workout.duration))
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }

            // Stats
            HStack(spacing: 20) {
                StatBadge(
                    icon: "dumbbell.fill",
                    value: "\(workout.exerciseCount)",
                    label: "Exercises"
                )

                StatBadge(
                    icon: "repeat",
                    value: "\(workout.totalSets)",
                    label: "Sets"
                )

                Spacer()
            }

            // Recent exercises
            if !workout.sets.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercises")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(Array(Set(workout.sets.map { $0.exerciseName })).prefix(3), id: \.self) { exerciseName in
                        Text("• \(exerciseName)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline.bold())

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
