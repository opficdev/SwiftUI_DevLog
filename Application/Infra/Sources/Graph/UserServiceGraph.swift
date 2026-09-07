//
//  UserServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class UserServiceGraph {
    public init() { }

    @Provide
    private func makeUserService() -> UserService {
        UserServiceImpl()
    }
}
