//
//  ProfileImageDataUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct ProfileImageDataUseCaseGraphInput {
    public let repository: ProfileImageDataRepository

    public init(repository: ProfileImageDataRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: ProfileImageDataUseCaseGraphInput.self)
public final class ProfileImageDataUseCaseGraph {
    @Provide
    private func makeFetchProfileImageDataUseCase() -> FetchProfileImageDataUseCase {
        FetchProfileImageDataUseCaseImpl(input.repository)
    }
}
