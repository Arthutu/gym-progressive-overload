import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var sessions: [WorkoutSession]

    @State private var selectedExercise: String?

    private var allExerciseNames: [String] {
        let allSets = sessions.flatMap { $0.sets }
        return Array(Set(allSets.map { $0.exerciseName })).sorted()
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

                if allExerciseNames.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            exerciseSelector

                            if let exercise = selectedExercise {
                                exerciseProgressCard(for: exercise)
                                exerciseHistoryChart(for: exercise)
                                volumeChart(for: exercise)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Progress")
            .onAppear {
                if selectedExercise == nil && !allExerciseNames.isEmpty {
                    selectedExercise = allExerciseNames.first
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 8) {
                Text("No Progress Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Complete workouts to see your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Exercise")
                .font(.headline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allExerciseNames, id: \.self) { exercise in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedExercise = exercise
                            }
                        } label: {
                            Text(exercise)
                                .font(.subheadline)
                                .fontWeight(selectedExercise == exercise ? .semibold : .regular)
                                .foregroundColor(selectedExercise == exercise ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedExercise == exercise ?
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [.gray.opacity(0.2), .gray.opacity(0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func exerciseProgressCard(for exercise: String) -> some View {
        let sets = getSetsFor(exercise: exercise)
        let maxWeight = sets.map { $0.weightLbs }.max() ?? 0
        let totalVolume = sets.reduce(0.0) { $0 + ($1.weightLbs * Double($1.reps)) }
        let totalSets = sets.count

        return VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                StatBox(
                    title: "Max Weight",
                    value: String(format: "%.0f", maxWeight),
                    unit: "lbs",
                    color: .blue
                )

                StatBox(
                    title: "Total Sets",
                    value: "\(totalSets)",
                    unit: "",
                    color: .purple
                )

                StatBox(
                    title: "Total Volume",
                    value: String(format: "%.0f", totalVolume / 1000),
                    unit: "k lbs",
                    color: .green
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    private func exerciseHistoryChart(for exercise: String) -> some View {
        let sets = getSetsFor(exercise: exercise).sorted { $0.timestamp < $1.timestamp }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Weight Progress")
                .font(.headline)
                .foregroundColor(.secondary)

            Chart {
                ForEach(sets) { set in
                    LineMark(
                        x: .value("Date", set.timestamp),
                        y: .value("Weight", set.weightLbs)
                    )
                    .foregroundStyle(.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", set.timestamp),
                        y: .value("Weight", set.weightLbs)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(Int(weight)) lbs")
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    private func volumeChart(for exercise: String) -> some View {
        let sets = getSetsFor(exercise: exercise).sorted { $0.timestamp < $1.timestamp }
        let sessionVolumes = calculateSessionVolumes(for: exercise)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Volume per Workout")
                .font(.headline)
                .foregroundColor(.secondary)

            Chart {
                ForEach(Array(sessionVolumes.enumerated()), id: \.offset) { index, item in
                    BarMark(
                        x: .value("Workout", index + 1),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(.purple.gradient)
                    .cornerRadius(8)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let volume = value.as(Double.self) {
                            Text("\(Int(volume / 1000))k")
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    private func getSetsFor(exercise: String) -> [WorkoutSet] {
        sessions.flatMap { $0.sets }.filter { $0.exerciseName == exercise }
    }

    private func calculateSessionVolumes(for exercise: String) -> [(session: WorkoutSession, volume: Double)] {
        sessions
            .filter { !$0.sets.filter { $0.exerciseName == exercise }.isEmpty }
            .map { session in
                let volume = session.sets
                    .filter { $0.exerciseName == exercise }
                    .reduce(0.0) { $0 + ($1.weightLbs * Double($1.reps)) }
                return (session, volume)
            }
            .sorted { $0.session.startTime < $1.session.startTime }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color.gradient)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ProgressView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}
