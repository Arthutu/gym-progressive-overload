import Foundation
import SwiftData
import CloudKit

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
    var id: UUID = UUID()
    var exerciseName: String = ""
    var reps: Int = 0
    var weightLbs: Double = 0.0
    var timestamp: Date = Date()
    var session: WorkoutSession?

    // CloudKit
    var cloudKitRecordID: String?
    var lastSyncedAt: Date?

    init(exerciseName: String, reps: Int, weightLbs: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.reps = reps
        self.weightLbs = weightLbs
        self.timestamp = timestamp
    }

    // Convert to CloudKit record
    func toCKRecord(sessionRecordID: String) -> CKRecord {
        let recordID = cloudKitRecordID != nil
            ? CKRecord.ID(recordName: cloudKitRecordID!)
            : CKRecord.ID(recordName: id.uuidString)

        let record = CKRecord(recordType: "WorkoutSet", recordID: recordID)
        record["exerciseName"] = exerciseName
        record["reps"] = reps
        record["weightLbs"] = weightLbs
        record["timestamp"] = timestamp

        // Reference to parent workout session
        let sessionReference = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: sessionRecordID),
            action: .deleteSelf
        )
        record["session"] = sessionReference

        return record
    }

    // Create from CloudKit record
    static func fromCKRecord(_ record: CKRecord) -> WorkoutSet? {
        guard let exerciseName = record["exerciseName"] as? String,
              let reps = record["reps"] as? Int,
              let weightLbs = record["weightLbs"] as? Double,
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }

        let set = WorkoutSet(
            exerciseName: exerciseName,
            reps: reps,
            weightLbs: weightLbs,
            timestamp: timestamp
        )
        set.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        set.cloudKitRecordID = record.recordID.recordName
        set.lastSyncedAt = record.modificationDate

        return set
    }
}

// MARK: - Workout Session
@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date?
    var isActive: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet] = []

    // CloudKit
    var cloudKitRecordID: String?
    var lastSyncedAt: Date?
    var userID: String? // Reference to User who owns this session

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

    // Convert to CloudKit record
    func toCKRecord(userID: String) -> CKRecord {
        let recordID = cloudKitRecordID != nil
            ? CKRecord.ID(recordName: cloudKitRecordID!)
            : CKRecord.ID(recordName: id.uuidString)

        let record = CKRecord(recordType: "WorkoutSession", recordID: recordID)
        record["startTime"] = startTime
        record["endTime"] = endTime
        record["isActive"] = isActive ? 1 : 0
        record["userID"] = userID
        record["totalSets"] = totalSets
        record["exerciseCount"] = exerciseCount
        record["duration"] = duration

        return record
    }

    // Create from CloudKit record
    static func fromCKRecord(_ record: CKRecord) -> WorkoutSession? {
        guard let startTime = record["startTime"] as? Date else {
            return nil
        }

        let session = WorkoutSession(startTime: startTime)
        session.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        session.endTime = record["endTime"] as? Date
        session.isActive = (record["isActive"] as? Int ?? 0) == 1
        session.cloudKitRecordID = record.recordID.recordName
        session.lastSyncedAt = record.modificationDate
        session.userID = record["userID"] as? String

        return session
    }
}
