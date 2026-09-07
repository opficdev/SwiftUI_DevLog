//
//  GoogleAuthenticationServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class GoogleAuthenticationServiceGraph {
    public init() { }

    @Provide
    private func makeGoogleAuthenticationService() -> GoogleAuthenticationService {
        GoogleAuthenticationServiceImpl()
    }
}
