//
//  AnalyticsServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class AnalyticsServiceGraph {
    public init() { }

    @Provide
    private func makeAnalyticsService() -> AnalyticsService {
        FirebaseAnalyticsServiceImpl()
    }
}
