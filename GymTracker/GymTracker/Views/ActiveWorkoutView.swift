import SwiftUI
import SwiftData
import ActivityKit

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: WorkoutSession
    @Binding var isPresented: Bool

    @State private var showingExerciseSelection = false
    @State private var selectedExercise: ExerciseInfo?
    @State private var showingSetEntry = false
    @State private var showingEndWorkoutAlert = false
    @State private var showingVoiceInput = false
    @State private var liveActivity: Activity<WorkoutActivityAttributes>?
    @State private var voiceService = VoiceRecognitionService()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        workoutStatsCard

                        if selectedExercise != nil {
                            currentExerciseSection
                        }

                        if !session.sets.isEmpty {
                            allSetsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End") {
                        showingEndWorkoutAlert = true
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingExerciseSelection = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingExerciseSelection) {
                ExerciseSelectionView(selectedExercise: $selectedExercise)
            }
            .sheet(isPresented: $showingSetEntry) {
                if let exercise = selectedExercise {
                    SetEntryView(
                        session: session,
                        exercise: exercise,
                        isPresented: $showingSetEntry
                    )
                }
            }
            .alert("End Workout?", isPresented: $showingEndWorkoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("End Workout", role: .destructive) {
                    endWorkout()
                }
            } message: {
                Text("Are you sure you want to end this workout?")
            }
            .sheet(isPresented: $showingVoiceInput) {
                VoiceInputView(
                    session: session,
                    voiceService: voiceService,
                    isPresented: $showingVoiceInput,
                    selectedExercise: $selectedExercise
                )
            }
            .onChange(of: selectedExercise) { _, newValue in
                if newValue != nil {
                    showingSetEntry = true
                }
            }
            .onAppear {
                startLiveActivity()
            }
            .onDisappear {
                endLiveActivity()
            }
            .onChange(of: session.sets.count) {
                updateLiveActivity()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private var workoutStatsCard: some View {
        HStack(spacing: 30) {
            VStack(spacing: 4) {
                Text("\(session.totalSets)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.blue.gradient)
                Text("Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 50)

            VStack(spacing: 4) {
                Text("\(session.exerciseCount)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.purple.gradient)
                Text("Exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 50)

            VStack(spacing: 4) {
                Text(formattedDuration)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.green.gradient)
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    private var currentExerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Exercise")
                .font(.headline)
                .foregroundColor(.secondary)

            if let exercise = selectedExercise {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(exercise.muscleGroup.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    let exerciseSets = session.sets.filter { $0.exerciseName == exercise.name }
                    if !exerciseSets.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(exerciseSets.sorted(by: { $0.timestamp > $1.timestamp })) { set in
                                HStack {
                                    Text("Set \(exerciseSets.firstIndex(where: { $0.id == set.id })! + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text("\(Int(set.weightLbs)) lbs × \(set.reps) reps")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Button {
                        showingSetEntry = true
                    } label: {
                        Label("Add Set", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
        }
    }

    private var allSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Sets")
                .font(.headline)
                .foregroundColor(.secondary)

            let groupedSets = Dictionary(grouping: session.sets, by: { $0.exerciseName })

            ForEach(Array(groupedSets.keys.sorted()), id: \.self) { exerciseName in
                if let sets = groupedSets[exerciseName] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exerciseName)
                            .font(.headline)

                        ForEach(sets.sorted(by: { $0.timestamp < $1.timestamp })) { set in
                            HStack {
                                Text("Set \(sets.firstIndex(where: { $0.id == set.id })! + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("\(Int(set.weightLbs)) lbs × \(set.reps) reps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    private var formattedDuration: String {
        let duration = session.duration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func endWorkout() {
        session.endSession()
        endLiveActivity()
        isPresented = false
    }

    // MARK: - Live Activity Methods
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = WorkoutActivityAttributes(
            workoutId: session.id.uuidString,
            startTime: session.startTime
        )

        let contentState = WorkoutActivityAttributes.ContentState(
            currentExercise: selectedExercise?.name ?? "No exercise selected",
            totalSets: session.totalSets,
            exerciseSets: getCurrentExerciseSets(),
            isRecording: voiceService.isRecording
        )

        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
        } catch {
            print("Error starting live activity: \(error)")
        }
    }

    private func updateLiveActivity() {
        guard let activity = liveActivity else { return }

        let contentState = WorkoutActivityAttributes.ContentState(
            currentExercise: selectedExercise?.name ?? "No exercise selected",
            totalSets: session.totalSets,
            exerciseSets: getCurrentExerciseSets(),
            isRecording: voiceService.isRecording
        )

        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        Task {
            await liveActivity?.end(nil, dismissalPolicy: .immediate)
            liveActivity = nil
        }
    }

    private func getCurrentExerciseSets() -> [WorkoutActivityAttributes.ContentState.ExerciseSet] {
        guard let exercise = selectedExercise else { return [] }

        return session.sets
            .filter { $0.exerciseName == exercise.name }
            .sorted { $0.timestamp > $1.timestamp }
            .map { set in
                WorkoutActivityAttributes.ContentState.ExerciseSet(
                    weight: set.weightLbs,
                    reps: set.reps,
                    timestamp: set.timestamp
                )
            }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "gymtracker" else { return }

        switch url.host {
        case "voice":
            showingVoiceInput = true
        case "manual":
            if selectedExercise != nil {
                showingSetEntry = true
            } else {
                showingExerciseSelection = true
            }
        case "end":
            showingEndWorkoutAlert = true
        default:
            break
        }
    }
}

struct SetEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    let exercise: ExerciseInfo
    @Binding var isPresented: Bool

    @State private var reps: String = ""
    @State private var weight: String = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case reps, weight
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(exercise.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(exercise.muscleGroup.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight (lbs)")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            TextField("0", text: $weight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 48, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .focused($focusedField, equals: .weight)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reps")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            TextField("0", text: $reps)
                                .keyboardType(.numberPad)
                                .font(.system(size: 48, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .focused($focusedField, equals: .reps)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        saveSet()
                    } label: {
                        Text("Save Set")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                canSave ?
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [.gray, .gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .disabled(!canSave)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                focusedField = .weight
            }
        }
    }

    private var canSave: Bool {
        guard let repsInt = Int(reps),
              let weightDouble = Double(weight) else {
            return false
        }
        return repsInt > 0 && weightDouble > 0
    }

    private func saveSet() {
        guard let repsInt = Int(reps),
              let weightDouble = Double(weight) else {
            return
        }

        let newSet = WorkoutSet(
            exerciseName: exercise.name,
            reps: repsInt,
            weightLbs: weightDouble
        )
        newSet.session = session
        modelContext.insert(newSet)

        isPresented = false
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, WorkoutSet.self, configurations: config)

    let session = WorkoutSession()
    container.mainContext.insert(session)

    return ActiveWorkoutView(session: session, isPresented: .constant(true))
        .modelContainer(container)
}
