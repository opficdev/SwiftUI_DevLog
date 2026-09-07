//
//  AnalyticsUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct AnalyticsUseCaseGraphInput {
    public let repository: AnalyticsRepository

    public init(repository: AnalyticsRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: AnalyticsUseCaseGraphInput.self)
public final class AnalyticsUseCaseGraph {
    @Provide
    private func makeTrackAnalyticsEventUseCase() -> TrackAnalyticsEventUseCase {
        TrackAnalyticsEventUseCaseImpl(input.repository)
    }
}
