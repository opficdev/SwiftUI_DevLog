//
//  GithubAuthenticationServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class GithubAuthenticationServiceGraph {
    public init() { }

    @Provide
    private func makeGithubAuthenticationService() -> GithubAuthenticationService {
        GithubAuthenticationServiceImpl()
    }
}
