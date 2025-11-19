import Foundation
import SwiftData
import CloudKit

@Model
final class User {
    var id: String = UUID().uuidString
    var appleUserID: String = ""
    var email: String?
    var displayName: String = ""
    var createdAt: Date = Date()
    var lastSyncedAt: Date?

    // Privacy settings
    var profileIsPublic: Bool = false
    var workoutsArePublic: Bool = false

    // CloudKit
    var cloudKitRecordID: String?

    init(
        id: String = UUID().uuidString,
        appleUserID: String,
        email: String? = nil,
        displayName: String,
        profileIsPublic: Bool = false,
        workoutsArePublic: Bool = false
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
        self.profileIsPublic = profileIsPublic
        self.workoutsArePublic = workoutsArePublic
    }

    // Convert to CloudKit record
    func toCKRecord() -> CKRecord {
        let recordID = cloudKitRecordID != nil
            ? CKRecord.ID(recordName: cloudKitRecordID!)
            : CKRecord.ID(recordName: id)

        let record = CKRecord(recordType: "User", recordID: recordID)
        record["appleUserID"] = appleUserID
        record["email"] = email
        record["displayName"] = displayName
        record["createdAt"] = createdAt
        record["profileIsPublic"] = profileIsPublic ? 1 : 0
        record["workoutsArePublic"] = workoutsArePublic ? 1 : 0

        return record
    }

    // Create from CloudKit record
    static func fromCKRecord(_ record: CKRecord) -> User? {
        guard let appleUserID = record["appleUserID"] as? String,
              let displayName = record["displayName"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        let user = User(
            id: record.recordID.recordName,
            appleUserID: appleUserID,
            email: record["email"] as? String,
            displayName: displayName,
            profileIsPublic: (record["profileIsPublic"] as? Int ?? 0) == 1,
            workoutsArePublic: (record["workoutsArePublic"] as? Int ?? 0) == 1
        )
        user.createdAt = createdAt
        user.cloudKitRecordID = record.recordID.recordName
        user.lastSyncedAt = record.modificationDate

        return user
    }
}
