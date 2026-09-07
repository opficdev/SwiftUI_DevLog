//
//  PushNotificationServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class PushNotificationServiceGraph {
    public init() { }

    @Provide
    private func makePushNotificationService() -> PushNotificationService {
        PushNotificationServiceImpl()
    }
}
