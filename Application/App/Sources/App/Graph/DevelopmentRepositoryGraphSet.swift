//
//  DevelopmentRepositoryGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Infra

final class DevelopmentRepositoryGraphSet {
    let developmentGoalRepositoryGraph: DevelopmentGoalRepositoryGraph
    let developmentRecordRepositoryGraph: DevelopmentRecordRepositoryGraph

    init(
        developmentGoalServiceGraph: DevelopmentGoalServiceGraph,
        developmentRecordServiceGraph: DevelopmentRecordServiceGraph
    ) {
        self.developmentGoalRepositoryGraph = DevelopmentGoalRepositoryGraph(
            input: DevelopmentGoalRepositoryGraphInput(
                service: developmentGoalServiceGraph.developmentGoalService
            )
        )
        self.developmentRecordRepositoryGraph = DevelopmentRecordRepositoryGraph(
            input: DevelopmentRecordRepositoryGraphInput(
                service: developmentRecordServiceGraph.developmentRecordService
            )
        )
    }
}
