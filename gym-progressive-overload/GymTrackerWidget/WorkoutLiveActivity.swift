import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentExercise: String
        var totalSets: Int
        var exerciseSets: [ExerciseSet]
        var isRecording: Bool

        struct ExerciseSet: Codable, Hashable {
            let weight: Double
            let reps: Int
            let timestamp: Date
        }
    }

    var workoutId: String
    var startTime: Date
}

// MARK: - Live Activity Widget
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Exercise")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.currentExercise)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 4) {
                        Text("\(context.state.totalSets)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue.gradient)
                        Text("Sets")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        if !context.state.exerciseSets.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(Array(context.state.exerciseSets.prefix(3).enumerated()), id: \.offset) { index, set in
                                    HStack {
                                        Text("Set \(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(set.weight)) lbs × \(set.reps)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        HStack(spacing: 12) {
                            Link(destination: URL(string: "gymtracker://voice")!) {
                                HStack {
                                    Image(systemName: context.state.isRecording ? "waveform" : "mic.fill")
                                        .font(.caption)
                                    Text(context.state.isRecording ? "Recording..." : "Voice Input")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(context.state.isRecording ? Color.red : Color.blue)
                                .cornerRadius(8)
                            }

                            Link(destination: URL(string: "gymtracker://manual")!) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                    Text("Manual")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.purple)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact leading (left side of notch)
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact trailing (right side of notch)
                Text("\(context.state.totalSets)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue.gradient)
            } minimal: {
                // Minimal view (when multiple activities)
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Workout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(context.state.currentExercise)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(context.state.totalSets)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue.gradient)
                    Text("Sets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if !context.state.exerciseSets.isEmpty {
                Divider()

                VStack(spacing: 6) {
                    ForEach(Array(context.state.exerciseSets.prefix(3).enumerated()), id: \.offset) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(set.weight)) lbs × \(set.reps) reps")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                Link(destination: URL(string: "gymtracker://voice")!) {
                    HStack {
                        Image(systemName: context.state.isRecording ? "waveform" : "mic.fill")
                        Text(context.state.isRecording ? "Recording" : "Voice")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(context.state.isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
                }

                Link(destination: URL(string: "gymtracker://manual")!) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Manual")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(10)
                }

                Link(destination: URL(string: "gymtracker://end")!) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

#Preview("Live Activity", as: .content, using: WorkoutActivityAttributes(workoutId: "123", startTime: Date())) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState(
        currentExercise: "Bench Press",
        totalSets: 3,
        exerciseSets: [
            .init(weight: 185, reps: 8, timestamp: Date()),
            .init(weight: 185, reps: 7, timestamp: Date()),
            .init(weight: 185, reps: 6, timestamp: Date())
        ],
        isRecording: false
    )
}
