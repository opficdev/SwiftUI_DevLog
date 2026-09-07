//
//  PushNotificationOpenHandlerGraph.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

struct PushNotificationOpenHandlerGraphInput {
    let analyticsService: AnalyticsService
}

@DependencyGraph(input: PushNotificationOpenHandlerGraphInput.self)
final class PushNotificationOpenHandlerGraph {
    @Provide(.lazy)
    private func makePushNotificationOpenHandler() -> PushNotificationOpenHandler {
        PushNotificationOpenHandler(analyticsService: input.analyticsService)
    }
}
