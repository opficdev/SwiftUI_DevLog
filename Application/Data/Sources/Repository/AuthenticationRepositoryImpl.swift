//
//  AuthenticationRepositoryImpl.swift
//  Data
//
//  Created by 최윤진 on 11/2/25.
//

import Domain

final class AuthenticationRepositoryImpl: AuthenticationRepository {
    private let authService: AuthService
    private let appleAuthService: AppleAuthenticationService
    private let githubAuthService: GithubAuthenticationService
    private let googleAuthService: GoogleAuthenticationService
    private let userService: UserService
    private let widgetSnapshotUpdater: WidgetSnapshotUpdater

    init(
        authService: AuthService,
        appleAuthService: AppleAuthenticationService,
        githubAuthService: GithubAuthenticationService,
        googleAuthService: GoogleAuthenticationService,
        userService: UserService,
        widgetSnapshotUpdater: WidgetSnapshotUpdater
    ) {
        self.authService = authService
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
        self.userService = userService
        self.widgetSnapshotUpdater = widgetSnapshotUpdater
    }

    func signIn(_ provider: AuthProvider) async throws -> Bool {
        authService.beginSignIn()

        do {
            let response: AuthDataResponse?
            switch provider {
            case .apple:
                response = try await appleAuthService.signIn()
            case .github:
                response = try await githubAuthService.signIn()
            case .google:
                response = try await googleAuthService.signIn()
            }

            guard let response else {
                authService.cancelSignIn()
                return false
            }

            try await userService.upsertUser(response)
            authService.completeSignIn()
            return true
        } catch {
            if authService.uid != nil {
                try? await authService.clearCurrentSession()
            }

            authService.cancelSignIn()
            throw mapSignInError(error)
        }
    }

    func signOut() async throws {
        let providers = authService.providerIDs.compactMap { AuthProvider(rawValue: $0) }

        do {
            try await authService.clearCurrentSession()
        } catch {
            throw error.toDomain()
        }

        clearProviderSessions(providers)
        widgetSnapshotUpdater.clear()
    }

    func delete() async throws {
        guard let uid = authService.uid else {
            throw AuthError.notAuthenticated
        }

        let providers = authService.providerIDs.compactMap { AuthProvider(rawValue: $0) }

        for provider in providers {
            switch provider {
            case .apple:
                try await appleAuthService.deleteAuth(uid)
            case .github:
                try await githubAuthService.deleteAuth(uid)
            case .google:
                try await googleAuthService.deleteAuth(uid)
            }
        }

        do {
            try await authService.deleteCurrentUser()
            try await authService.clearCurrentSession()
            clearProviderSessions(providers)
            widgetSnapshotUpdater.clear()
        } catch {
            throw error.toDomain()
        }
    }
}

private extension AuthenticationRepositoryImpl {
    func clearProviderSessions(_ providers: [AuthProvider]) {
        for provider in providers {
            switch provider {
            case .apple:
                appleAuthService.clearLocalSession()
            case .github:
                githubAuthService.clearLocalSession()
            case .google:
                googleAuthService.clearLocalSession()
            }
        }
    }

    func mapSignInError(_ error: Error) -> Error {
        if let emailError = error as? EmailError,
           emailError == .notFound {
            return AuthError.emailNotFound
        }

        return error.toDomain()
    }
}
