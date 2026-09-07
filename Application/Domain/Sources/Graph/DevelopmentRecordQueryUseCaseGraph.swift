//
//  DevelopmentRecordQueryUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct DevelopmentRecordQueryUseCaseGraphInput {
    public let repository: DevelopmentRecordRepository

    public init(repository: DevelopmentRecordRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: DevelopmentRecordQueryUseCaseGraphInput.self)
public final class DevelopmentRecordQueryUseCaseGraph {
    @Provide
    private func makeFetchDevelopmentRecordsUseCase() -> FetchDevelopmentRecordsUseCase {
        FetchDevelopmentRecordsUseCaseImpl(input.repository)
    }

    @Provide
    private func makeFetchDevelopmentRecordHistoryUseCase() -> FetchDevelopmentRecordHistoryUseCase {
        FetchDevelopmentRecordHistoryUseCaseImpl(input.repository)
    }
}
