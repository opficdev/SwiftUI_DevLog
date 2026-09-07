//
//  UserDataUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct UserDataUseCaseGraphInput {
    public let repository: UserDataRepository

    public init(repository: UserDataRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: UserDataUseCaseGraphInput.self)
public final class UserDataUseCaseGraph {
    @Provide
    private func makeFetchUserDataUseCase() -> FetchUserDataUseCase {
        FetchUserDataUseCaseImpl(input.repository)
    }

    @Provide
    private func makeUpsertStatusMessageUseCase() -> UpsertStatusMessageUseCase {
        UpsertStatusMessageUseCaseImpl(input.repository)
    }
}
