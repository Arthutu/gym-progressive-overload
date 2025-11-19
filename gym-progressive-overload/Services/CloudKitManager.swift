import Foundation
import CloudKit
import SwiftData

@Observable
class CloudKitManager {
    private let container: CKContainer
    private var privateDatabase: CKDatabase
    private var publicDatabase: CKDatabase

    var isSyncing = false
    var lastSyncDate: Date?
    var syncError: String?

    init() {
        container = CKContainer(identifier: "iCloud.alrinc.gym-progressive-overload")
        privateDatabase = container.privateCloudDatabase
        publicDatabase = container.publicCloudDatabase
    }

    // MARK: - User Sync
    func saveUser(_ user: User) async throws {
        let record = user.toCKRecord()
        let savedRecord = try await privateDatabase.save(record)
        user.cloudKitRecordID = savedRecord.recordID.recordName
        user.lastSyncedAt = Date()
    }

    func fetchUser(appleUserID: String) async throws -> User? {
        let predicate = NSPredicate(format: "appleUserID == %@", appleUserID)
        let query = CKQuery(recordType: "User", predicate: predicate)

        let results = try await privateDatabase.records(matching: query)
        guard let (_, result) = results.matchResults.first,
              let record = try? result.get() else {
            return nil
        }

        return User.fromCKRecord(record)
    }

    // MARK: - Workout Session Sync
    func syncWorkoutSession(_ session: WorkoutSession, userID: String, isPublic: Bool) async throws {
        let record = session.toCKRecord(userID: userID)

        // Save to appropriate database based on privacy setting
        let database = isPublic ? publicDatabase : privateDatabase
        let savedRecord = try await database.save(record)

        session.cloudKitRecordID = savedRecord.recordID.recordName
        session.lastSyncedAt = Date()
    }

    func fetchWorkoutSessions(userID: String, isPublic: Bool) async throws -> [WorkoutSession] {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "WorkoutSession", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

        let database = isPublic ? publicDatabase : privateDatabase
        let results = try await database.records(matching: query)

        var sessions: [WorkoutSession] = []
        for (_, result) in results.matchResults {
            if let record = try? result.get(),
               let session = WorkoutSession.fromCKRecord(record) {
                sessions.append(session)
            }
        }

        return sessions
    }

    // MARK: - Public Feed
    func fetchPublicWorkouts(limit: Int = 50) async throws -> [WorkoutSession] {
        let predicate = NSPredicate(value: true) // Fetch all public workouts
        let query = CKQuery(recordType: "WorkoutSession", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

        let results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: limit)

        var sessions: [WorkoutSession] = []
        for (_, result) in results.matchResults {
            if let record = try? result.get(),
               let session = WorkoutSession.fromCKRecord(record) {
                sessions.append(session)
            }
        }

        return sessions
    }

    // MARK: - Sync All
    func syncAllData(for user: User, modelContext: ModelContext) async throws {
        guard !isSyncing else { return }

        isSyncing = true
        syncError = nil

        defer {
            isSyncing = false
            lastSyncDate = Date()
        }

        do {
            // 1. Sync user profile
            try await saveUser(user)

            // 2. Fetch all local workout sessions
            let descriptor = FetchDescriptor<WorkoutSession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            let localSessions = try modelContext.fetch(descriptor)

            // 3. Sync each session based on privacy settings
            for session in localSessions {
                // Only sync completed workouts
                if session.endTime != nil {
                    try await syncWorkoutSession(
                        session,
                        userID: user.id,
                        isPublic: user.workoutsArePublic
                    )
                }
            }

            // 4. Fetch remote sessions and merge
            let remoteSessions = try await fetchWorkoutSessions(
                userID: user.id,
                isPublic: user.workoutsArePublic
            )

            // Merge remote sessions that don't exist locally
            for remoteSession in remoteSessions {
                let existsLocally = localSessions.contains { $0.id == remoteSession.id }
                if !existsLocally {
                    modelContext.insert(remoteSession)
                }
            }

            try modelContext.save()

        } catch {
            syncError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Delete
    func deleteWorkoutSession(recordID: String, isPublic: Bool) async throws {
        let ckRecordID = CKRecord.ID(recordName: recordID)
        let database = isPublic ? publicDatabase : privateDatabase
        try await database.deleteRecord(withID: ckRecordID)
    }

    func deleteAllUserData(userID: String, cloudKitRecordID: String?) async throws {
        // Delete all workout sessions from both databases
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "WorkoutSession", predicate: predicate)

        // Delete from private database
        let privateResults = try await privateDatabase.records(matching: query)
        for (recordID, _) in privateResults.matchResults {
            try? await privateDatabase.deleteRecord(withID: recordID)
        }

        // Delete from public database
        let publicResults = try await publicDatabase.records(matching: query)
        for (recordID, _) in publicResults.matchResults {
            try? await publicDatabase.deleteRecord(withID: recordID)
        }

        // Delete user record if it exists
        if let userRecordID = cloudKitRecordID {
            let ckRecordID = CKRecord.ID(recordName: userRecordID)
            try? await privateDatabase.deleteRecord(withID: ckRecordID)
        }
    }
}
