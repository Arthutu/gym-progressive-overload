import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var authManager: AuthenticationManager
    @State private var isSigningIn = false

    init(authManager: AuthenticationManager) {
        _authManager = State(initialValue: authManager)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)

                    Text("Gym Tracker")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Track your progress, achieve your goals")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Sign In Button
                VStack(spacing: 20) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)

                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                    }

                    if let error = authManager.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 40)
                    }
                }

                Spacer()
                    .frame(height: 60)
            }
            .padding()
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        isSigningIn = true

        Task {
            switch result {
            case .success(let authorization):
                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    let userIdentifier = credential.user
                    let fullName = credential.fullName
                    let email = credential.email

                    // Create display name
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
                        authManager.currentUser = existingUser
                    } else {
                        // Create new user
                        let newUser = User(
                            appleUserID: userIdentifier,
                            email: email,
                            displayName: displayName
                        )
                        modelContext.insert(newUser)
                        try? modelContext.save()
                        authManager.currentUser = newUser
                    }

                    authManager.isAuthenticated = true
                    authManager.error = nil
                }

            case .failure(let error):
                authManager.error = error.localizedDescription
            }

            isSigningIn = false
        }
    }
}
