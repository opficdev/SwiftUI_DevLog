//
//  FCMTokenSyncHandlerGraph.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

struct FCMTokenSyncHandlerGraphInput {
    let authService: AuthService
    let messagingService: PushMessagingService
    let userService: UserService
}

@DependencyGraph(input: FCMTokenSyncHandlerGraphInput.self)
final class FCMTokenSyncHandlerGraph {
    @Provide(.lazy)
    private func makeFCMTokenSyncHandler() -> FCMTokenSyncHandler {
        FCMTokenSyncHandler(
            authService: input.authService,
            messagingService: input.messagingService,
            userService: input.userService
        )
    }
}
