//
//  DevelopmentRecordMutationUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct DevelopmentRecordMutationGraphInput {
    public let repository: DevelopmentRecordRepository
    public let goalRepository: DevelopmentGoalRepository

    public init(
        repository: DevelopmentRecordRepository,
        goalRepository: DevelopmentGoalRepository
    ) {
        self.repository = repository
        self.goalRepository = goalRepository
    }
}

@DependencyGraph(input: DevelopmentRecordMutationGraphInput.self)
public final class DevelopmentRecordMutationUseCaseGraph {
    @Provide
    private func makeCreateDevelopmentRecordUseCase() -> CreateDevelopmentRecordUseCase {
        CreateDevelopmentRecordUseCaseImpl(input.repository, input.goalRepository)
    }

    @Provide
    private func makeSaveDevelopmentRecordDraftUseCase() -> SaveDevelopmentRecordDraftUseCase {
        SaveDevelopmentRecordDraftUseCaseImpl(input.repository, input.goalRepository)
    }

    @Provide
    private func makeConfirmDevelopmentRecordUseCase() -> ConfirmDevelopmentRecordUseCase {
        ConfirmDevelopmentRecordUseCaseImpl(input.repository, input.goalRepository)
    }

    @Provide
    private func makeRestoreDevelopmentRecordUseCase() -> RestoreDevelopmentRecordUseCase {
        RestoreDevelopmentRecordUseCaseImpl(input.repository, input.goalRepository)
    }
}
