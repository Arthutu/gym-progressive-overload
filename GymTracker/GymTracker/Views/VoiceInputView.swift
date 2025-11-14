import SwiftUI
import SwiftData

struct VoiceInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    @Bindable var voiceService: VoiceRecognitionService
    @Binding var isPresented: Bool
    @Binding var selectedExercise: ExerciseInfo?

    @State private var parsedData: VoiceSetData?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Microphone animation
                    ZStack {
                        Circle()
                            .fill(voiceService.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .scaleEffect(voiceService.isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: voiceService.isRecording)

                        Circle()
                            .fill(voiceService.isRecording ? Color.red.opacity(0.3) : Color.blue.opacity(0.3))
                            .frame(width: 150, height: 150)

                        Image(systemName: voiceService.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(voiceService.isRecording ? .red.gradient : .blue.gradient)
                    }

                    VStack(spacing: 12) {
                        Text(voiceService.isRecording ? "Listening..." : "Tap to speak")
                            .font(.title2)
                            .fontWeight(.bold)

                        if !voiceService.transcription.isEmpty {
                            Text(voiceService.transcription)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Say: \"Bench press, 185 pounds, 8 reps\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if let error = voiceService.error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }

                    if let data = parsedData {
                        parsedDataCard(data)
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        Button {
                            toggleRecording()
                        } label: {
                            Text(voiceService.isRecording ? "Stop" : "Start Recording")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: voiceService.isRecording ? [.red, .orange] : [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }

                        if parsedData != nil {
                            Button {
                                saveSet()
                            } label: {
                                Text("Save Set")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        if voiceService.isRecording {
                            voiceService.stopRecording()
                        }
                        dismiss()
                    }
                }
            }
            .onChange(of: voiceService.transcription) { _, newValue in
                if !newValue.isEmpty && !voiceService.isRecording {
                    parseTranscription(newValue)
                }
            }
        }
    }

    private func parsedDataCard(_ data: VoiceSetData) -> some View {
        VStack(spacing: 16) {
            Text("Parsed Set")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                HStack {
                    Text("Exercise:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(data.exerciseName)
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("Weight:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(data.weight)) lbs")
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("Reps:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(data.reps)")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private func toggleRecording() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            parsedData = nil
            voiceService.error = nil
            Task {
                do {
                    try await voiceService.startRecording()
                } catch {
                    voiceService.error = error.localizedDescription
                }
            }
        }
    }

    private func parseTranscription(_ text: String) {
        if let data = voiceService.parseSetData(from: text) {
            parsedData = data

            // Try to find and set the exercise
            if let exercise = ExerciseDatabase.findExercise(byName: data.exerciseName) {
                selectedExercise = exercise
            }
        } else {
            voiceService.error = "Could not parse set data. Please try again."
        }
    }

    private func saveSet() {
        guard let data = parsedData else { return }

        let exerciseName = ExerciseDatabase.findExercise(byName: data.exerciseName)?.name ?? data.exerciseName

        let newSet = WorkoutSet(
            exerciseName: exerciseName,
            reps: data.reps,
            weightLbs: data.weight
        )
        newSet.session = session
        modelContext.insert(newSet)

        if voiceService.isRecording {
            voiceService.stopRecording()
        }

        isPresented = false
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, WorkoutSet.self, configurations: config)

    let session = WorkoutSession()
    container.mainContext.insert(session)

    return VoiceInputView(
        session: session,
        voiceService: VoiceRecognitionService(),
        isPresented: .constant(true),
        selectedExercise: .constant(nil)
    )
    .modelContainer(container)
}
