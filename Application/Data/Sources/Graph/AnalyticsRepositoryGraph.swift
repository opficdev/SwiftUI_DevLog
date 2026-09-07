//
//  AnalyticsRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct AnalyticsRepositoryGraphInput {
    public let analyticsService: AnalyticsService

    public init(analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
    }
}

@DependencyGraph(input: AnalyticsRepositoryGraphInput.self)
public final class AnalyticsRepositoryGraph {
    @Provide
    private func makeAnalyticsRepository() -> AnalyticsRepository {
        AnalyticsRepositoryImpl(analyticsService: input.analyticsService)
    }
}
