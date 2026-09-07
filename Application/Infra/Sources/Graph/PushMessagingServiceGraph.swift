//
//  PushMessagingServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class PushMessagingServiceGraph {
    public init() { }

    @Provide
    private func makePushMessagingService() -> PushMessagingService {
        PushMessagingServiceImpl()
    }
}
