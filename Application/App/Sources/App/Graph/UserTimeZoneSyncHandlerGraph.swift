//
//  UserTimeZoneSyncHandlerGraph.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

struct UserTimeZoneSyncHandlerGraphInput {
    let authService: AuthService
    let userService: UserService
}

@DependencyGraph(input: UserTimeZoneSyncHandlerGraphInput.self)
final class UserTimeZoneSyncHandlerGraph {
    @Provide(.lazy)
    private func makeUserTimeZoneSyncHandler() -> UserTimeZoneSyncHandler {
        UserTimeZoneSyncHandler(
            authService: input.authService,
            userService: input.userService
        )
    }
}
