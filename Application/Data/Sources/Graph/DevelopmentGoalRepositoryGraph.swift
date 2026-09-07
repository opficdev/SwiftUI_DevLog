//
//  DevelopmentGoalRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct DevelopmentGoalRepositoryGraphInput {
    public let service: DevelopmentGoalService

    public init(service: DevelopmentGoalService) {
        self.service = service
    }
}

@DependencyGraph(input: DevelopmentGoalRepositoryGraphInput.self)
public final class DevelopmentGoalRepositoryGraph {
    @Provide
    private func makeDevelopmentGoalRepository() -> DevelopmentGoalRepository {
        DevelopmentGoalRepositoryImpl(service: input.service)
    }
}
