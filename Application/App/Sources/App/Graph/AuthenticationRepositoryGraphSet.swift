//
//  AuthenticationRepositoryGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Infra
import Widget

final class AuthenticationRepositoryGraphSet {
    let authenticationRepositoryGraph: AuthenticationRepositoryGraph
    let authDataRepositoryGraph: AuthDataRepositoryGraph

    init(
        authServiceGraph: AuthServiceGraph,
        appleAuthenticationServiceGraph: AppleAuthenticationServiceGraph,
        githubAuthenticationServiceGraph: GithubAuthenticationServiceGraph,
        googleAuthenticationServiceGraph: GoogleAuthenticationServiceGraph,
        userServiceGraph: UserServiceGraph,
        widgetSnapshotUpdaterGraph: WidgetSnapshotUpdaterGraph
    ) {
        self.authenticationRepositoryGraph = AuthenticationRepositoryGraph(
            input: AuthenticationRepositoryGraphInput(
                authService: authServiceGraph.authService,
                appleAuthService: appleAuthenticationServiceGraph.appleAuthenticationService,
                githubAuthService: githubAuthenticationServiceGraph.githubAuthenticationService,
                googleAuthService: googleAuthenticationServiceGraph.googleAuthenticationService,
                userService: userServiceGraph.userService,
                widgetSnapshotUpdater: widgetSnapshotUpdaterGraph.widgetSnapshotUpdater
            )
        )
        self.authDataRepositoryGraph = AuthDataRepositoryGraph(
            input: AuthDataRepositoryGraphInput(
                authService: authServiceGraph.authService,
                appleAuthService: appleAuthenticationServiceGraph.appleAuthenticationService,
                githubAuthService: githubAuthenticationServiceGraph.githubAuthenticationService,
                googleAuthService: googleAuthenticationServiceGraph.googleAuthenticationService
            )
        )
    }
}
