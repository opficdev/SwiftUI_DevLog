//
//  UserDataRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct UserDataRepositoryGraphInput {
    public let userService: UserService

    public init(userService: UserService) {
        self.userService = userService
    }
}

@DependencyGraph(input: UserDataRepositoryGraphInput.self)
public final class UserDataRepositoryGraph {
    @Provide
    private func makeUserDataRepository() -> UserDataRepository {
        UserDataRepositoryImpl(userService: input.userService)
    }
}
