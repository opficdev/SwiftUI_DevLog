//
//  AuthServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class AuthServiceGraph {
    public init() { }

    @Provide
    private func makeAuthService() -> AuthService {
        AuthServiceImpl()
    }
}
