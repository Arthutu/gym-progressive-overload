import Foundation
import Speech
import AVFoundation

struct VoiceSetData {
    let exerciseName: String
    let weight: Double
    let reps: Int
}

@Observable
class VoiceRecognitionService: NSObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var isRecording = false
    var transcription = ""
    var error: String?

    func requestPermissions() async -> Bool {
        let speechStatus = await SFSpeechRecognizer.requestAuthorization()
        guard speechStatus == .authorized else {
            error = "Speech recognition not authorized"
            return false
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session error: \(error.localizedDescription)"
            return false
        }

        return true
    }

    func startRecording() async throws {
        guard await requestPermissions() else {
            throw NSError(domain: "VoiceRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permissions not granted"])
        }

        // Cancel previous task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcription = ""

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.transcription = result.bestTranscription.formattedString
            }

            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    func parseSetData(from text: String) -> VoiceSetData? {
        let lowercased = text.lowercased()

        // Extract exercise name - everything before the first number
        var exerciseName: String?
        var weight: Double?
        var reps: Int?

        // Pattern 1: "Bench press, 185 pounds, 8 reps"
        // Pattern 2: "Bench press 185 pounds 8 reps"
        // Pattern 3: "185 pounds 8 reps bench press"

        // Extract numbers
        let numberPattern = "\\d+\\.?\\d*"
        let regex = try? NSRegularExpression(pattern: numberPattern)
        let matches = regex?.matches(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased))

        var numbers: [Double] = []
        if let matches = matches {
            for match in matches {
                if let range = Range(match.range, in: lowercased) {
                    if let number = Double(String(lowercased[range])) {
                        numbers.append(number)
                    }
                }
            }
        }

        // Try to identify weight and reps from numbers
        // Usually weight is larger than reps, but weight could also come first
        if numbers.count >= 2 {
            // Check which number is mentioned with "pound" or "lbs"
            if lowercased.contains("pound") || lowercased.contains("lbs") || lowercased.contains("lb") {
                // Find weight indicator position
                let poundsRange = lowercased.range(of: "pound") ?? lowercased.range(of: "lbs") ?? lowercased.range(of: "lb")

                // Find which number is closer to "pounds"
                if let poundsRange = poundsRange {
                    // Simple heuristic: first number is usually weight
                    weight = numbers[0]
                    reps = Int(numbers[1])
                }
            } else {
                // No explicit weight indicator, assume first number is weight
                weight = numbers[0]
                reps = Int(numbers[1])
            }
        }

        // Extract exercise name - get text before first number
        if let firstNumberMatch = matches?.first,
           let range = Range(firstNumberMatch.range, in: lowercased) {
            let beforeNumber = String(lowercased[..<range.lowerBound])
            let cleanedName = beforeNumber
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: ","))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !cleanedName.isEmpty {
                exerciseName = cleanedName.capitalized
            }
        }

        // If no exercise name found, try to match with database
        if exerciseName == nil || exerciseName?.isEmpty == true {
            for exercise in ExerciseDatabase.allExercises {
                if lowercased.contains(exercise.name.lowercased()) {
                    exerciseName = exercise.name
                    break
                }
            }
        }

        // Validate we have all required data
        guard let exercise = exerciseName,
              let w = weight,
              let r = reps else {
            return nil
        }

        return VoiceSetData(exerciseName: exercise, weight: w, reps: r)
    }
}
