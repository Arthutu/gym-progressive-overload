import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var sessions: [WorkoutSession]

    @State private var showingActiveWorkout = false
    @State private var activeSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if sessions.isEmpty && activeSession == nil {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let active = activeSession {
                                activeSessionCard(active)
                                    .padding(.horizontal)
                                    .padding(.top)
                            }

                            if !sessions.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Past Workouts")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)

                                    ForEach(sessions) { session in
                                        if !session.isActive {
                                            WorkoutSessionCard(session: session)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        startNewWorkout()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingActiveWorkout) {
                if let session = activeSession {
                    ActiveWorkoutView(session: session, isPresented: $showingActiveWorkout)
                }
            }
            .onAppear {
                checkForActiveSession()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 8) {
                Text("No Workouts Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start your first workout to track your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                startNewWorkout()
            } label: {
                Label("Start Workout", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
        }
        .padding()
    }

    private func activeSessionCard(_ session: WorkoutSession) -> some View {
        Button {
            showingActiveWorkout = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.green)
                    Text("Active Workout")
                        .font(.headline)
                        .foregroundColor(.green)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("\(session.totalSets)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("\(session.exerciseCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private func startNewWorkout() {
        let newSession = WorkoutSession()
        modelContext.insert(newSession)
        activeSession = newSession
        showingActiveWorkout = true
    }

    private func checkForActiveSession() {
        activeSession = sessions.first { $0.isActive }
    }
}

struct WorkoutSessionCard: View {
    let session: WorkoutSession

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private var durationFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: session.startTime))
                        .font(.headline)

                    if let duration = durationFormatter.string(from: session.duration) {
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            HStack(spacing: 20) {
                Label("\(session.totalSets)", systemImage: "number")
                    .font(.subheadline)
                Label("\(session.exerciseCount)", systemImage: "list.bullet")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)

            if let sets = session.sets, !sets.isEmpty {
                let uniqueExercises = Array(Set(sets.map { $0.exerciseName })).prefix(3)
                HStack(spacing: 8) {
                    ForEach(Array(uniqueExercises), id: \.self) { exercise in
                        Text(exercise)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

#Preview {
    WorkoutListView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}
