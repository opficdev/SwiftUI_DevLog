//
//  AuthenticationRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct AuthenticationRepositoryGraphInput {
    public let authService: AuthService
    public let appleAuthService: AppleAuthenticationService
    public let githubAuthService: GithubAuthenticationService
    public let googleAuthService: GoogleAuthenticationService
    public let userService: UserService
    public let widgetSnapshotUpdater: WidgetSnapshotUpdater

    public init(
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
}

@DependencyGraph(input: AuthenticationRepositoryGraphInput.self)
public final class AuthenticationRepositoryGraph {
    @Provide
    private func makeAuthenticationRepository() -> AuthenticationRepository {
        AuthenticationRepositoryImpl(
            authService: input.authService,
            appleAuthService: input.appleAuthService,
            githubAuthService: input.githubAuthService,
            googleAuthService: input.googleAuthService,
            userService: input.userService,
            widgetSnapshotUpdater: input.widgetSnapshotUpdater
        )
    }
}
