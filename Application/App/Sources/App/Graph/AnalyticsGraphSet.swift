//
//  AnalyticsGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra

final class AnalyticsGraphSet {
    let analyticsRepositoryGraph: AnalyticsRepositoryGraph
    let analyticsUseCaseGraph: AnalyticsUseCaseGraph

    init(analyticsServiceGraph: AnalyticsServiceGraph) {
        self.analyticsRepositoryGraph = AnalyticsRepositoryGraph(
            input: AnalyticsRepositoryGraphInput(
                analyticsService: analyticsServiceGraph.analyticsService
            )
        )
        self.analyticsUseCaseGraph = AnalyticsUseCaseGraph(
            input: AnalyticsUseCaseGraphInput(
                repository: analyticsRepositoryGraph.analyticsRepository
            )
        )
    }
}
