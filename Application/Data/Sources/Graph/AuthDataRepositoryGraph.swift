//
//  AuthDataRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct AuthDataRepositoryGraphInput {
    public let authService: AuthService
    public let appleAuthService: AppleAuthenticationService
    public let githubAuthService: GithubAuthenticationService
    public let googleAuthService: GoogleAuthenticationService

    public init(
        authService: AuthService,
        appleAuthService: AppleAuthenticationService,
        githubAuthService: GithubAuthenticationService,
        googleAuthService: GoogleAuthenticationService
    ) {
        self.authService = authService
        self.appleAuthService = appleAuthService
        self.githubAuthService = githubAuthService
        self.googleAuthService = googleAuthService
    }
}

@DependencyGraph(input: AuthDataRepositoryGraphInput.self)
public final class AuthDataRepositoryGraph {
    @Provide
    private func makeAuthDataRepository() -> AuthDataRepository {
        AuthDataRepositoryImpl(
            authService: input.authService,
            appleAuthService: input.appleAuthService,
            githubAuthService: input.githubAuthService,
            googleAuthService: input.googleAuthService
        )
    }
}
