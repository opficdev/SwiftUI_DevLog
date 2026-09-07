//
//  ProfileImageDataRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct ProfileImageDataRepositoryGraphInput {
    public let service: ProfileImageDataService
    public let store: MemoryCacheStore

    public init(
        service: ProfileImageDataService,
        store: MemoryCacheStore
    ) {
        self.service = service
        self.store = store
    }
}

@DependencyGraph(input: ProfileImageDataRepositoryGraphInput.self)
public final class ProfileImageDataRepositoryGraph {
    @Provide
    private func makeProfileImageDataRepository() -> ProfileImageDataRepository {
        ProfileImageDataRepositoryImpl(
            service: input.service,
            store: input.store
        )
    }
}
