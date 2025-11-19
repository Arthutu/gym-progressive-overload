import Foundation
import AuthenticationServices
import SwiftData

@Observable
class AuthenticationManager: NSObject {
    var currentUser: User?
    var isAuthenticated = false
    var error: String?

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthenticationState()
    }

    private func checkAuthenticationState() {
        // Check if we have a stored user
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<User>()
        if let users = try? modelContext.fetch(descriptor),
           let user = users.first {
            currentUser = user
            isAuthenticated = true
        }
    }

    func signIn() async -> Bool {
        await withCheckedContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()

            // Store continuation for later use
            signInContinuation = continuation
        }
    }

    func signOut() {
        guard let modelContext = modelContext else { return }

        if let user = currentUser {
            modelContext.delete(user)
            try? modelContext.save()
        }

        currentUser = nil
        isAuthenticated = false
    }

    private var signInContinuation: CheckedContinuation<Bool, Never>?
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let modelContext = modelContext else {
            signInContinuation?.resume(returning: false)
            return
        }

        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email

            // Create display name from full name or use default
            var displayName = "User"
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                displayName = "\(givenName) \(familyName)"
            } else if let givenName = fullName?.givenName {
                displayName = givenName
            }

            // Check if user already exists
            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.appleUserID == userIdentifier }
            )

            if let existingUser = try? modelContext.fetch(descriptor).first {
                currentUser = existingUser
            } else {
                // Create new user
                let newUser = User(
                    appleUserID: userIdentifier,
                    email: email,
                    displayName: displayName
                )
                modelContext.insert(newUser)
                try? modelContext.save()
                currentUser = newUser
            }

            isAuthenticated = true
            error = nil
            signInContinuation?.resume(returning: true)
        } else {
            error = "Invalid credential type"
            signInContinuation?.resume(returning: false)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = error.localizedDescription
        signInContinuation?.resume(returning: false)
    }
}
