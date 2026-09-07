//
//  DevelopmentGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra

final class DevelopmentGraphSet {
    let developmentGoalRepositoryGraph: DevelopmentGoalRepositoryGraph
    let developmentRecordRepositoryGraph: DevelopmentRecordRepositoryGraph
    let developmentGoalUseCaseGraph: DevelopmentGoalUseCaseGraph
    let developmentRecordQueryUseCaseGraph: DevelopmentRecordQueryUseCaseGraph
    let developmentRecordMutationUseCaseGraph: DevelopmentRecordMutationUseCaseGraph

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
        self.developmentGoalUseCaseGraph = DevelopmentGoalUseCaseGraph(
            input: DevelopmentGoalUseCaseGraphInput(
                repository: developmentGoalRepositoryGraph.developmentGoalRepository
            )
        )
        self.developmentRecordQueryUseCaseGraph = DevelopmentRecordQueryUseCaseGraph(
            input: DevelopmentRecordQueryUseCaseGraphInput(
                repository: developmentRecordRepositoryGraph.developmentRecordRepository
            )
        )
        self.developmentRecordMutationUseCaseGraph = DevelopmentRecordMutationUseCaseGraph(
            input: DevelopmentRecordMutationGraphInput(
                repository: developmentRecordRepositoryGraph.developmentRecordRepository,
                goalRepository: developmentGoalRepositoryGraph.developmentGoalRepository
            )
        )
    }
}
