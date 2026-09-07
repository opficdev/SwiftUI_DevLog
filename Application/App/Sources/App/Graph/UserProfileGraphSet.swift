//
//  UserProfileGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra
import Persistence

final class UserProfileGraphSet {
    let userDataRepositoryGraph: UserDataRepositoryGraph
    let profileImageDataRepositoryGraph: ProfileImageDataRepositoryGraph
    let userDataUseCaseGraph: UserDataUseCaseGraph
    let profileImageDataUseCaseGraph: ProfileImageDataUseCaseGraph

    init(
        userServiceGraph: UserServiceGraph,
        profileImageDataServiceGraph: ProfileImageDataServiceGraph,
        memoryCacheStoreGraph: MemoryCacheStoreGraph
    ) {
        self.userDataRepositoryGraph = UserDataRepositoryGraph(
            input: UserDataRepositoryGraphInput(
                userService: userServiceGraph.userService
            )
        )
        self.profileImageDataRepositoryGraph = ProfileImageDataRepositoryGraph(
            input: ProfileImageDataRepositoryGraphInput(
                service: profileImageDataServiceGraph.profileImageDataService,
                store: memoryCacheStoreGraph.memoryCacheStore
            )
        )
        self.userDataUseCaseGraph = UserDataUseCaseGraph(
            input: UserDataUseCaseGraphInput(
                repository: userDataRepositoryGraph.userDataRepository
            )
        )
        self.profileImageDataUseCaseGraph = ProfileImageDataUseCaseGraph(
            input: ProfileImageDataUseCaseGraphInput(
                repository: profileImageDataRepositoryGraph.profileImageDataRepository
            )
        )
    }
}
