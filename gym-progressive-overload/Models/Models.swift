import Foundation
import SwiftData

// MARK: - Muscle Group
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Chest"
    case lowerBack = "Lower Back"
    case middleBack = "Middle Back"
    case lats = "Lats"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
}

// MARK: - Exercise Info
struct ExerciseInfo: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let muscleGroup: MuscleGroup

    init(id: String? = nil, name: String, muscleGroup: MuscleGroup) {
        self.id = id ?? name
        self.name = name
        self.muscleGroup = muscleGroup
    }
}

// MARK: - Workout Set
@Model
final class WorkoutSet {
    var id: UUID
    var exerciseName: String
    var reps: Int
    var weightLbs: Double
    var timestamp: Date
    var session: WorkoutSession?

    init(exerciseName: String, reps: Int, weightLbs: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.reps = reps
        self.weightLbs = weightLbs
        self.timestamp = timestamp
    }
}

// MARK: - Workout Session
@Model
final class WorkoutSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet]

    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
        self.isActive = true
        self.sets = []
    }

    func endSession() {
        self.endTime = Date()
        self.isActive = false
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var totalSets: Int {
        sets.count
    }

    var exerciseCount: Int {
        Set(sets.map { $0.exerciseName }).count
    }
}
