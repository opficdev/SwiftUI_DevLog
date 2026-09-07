//
//  AppleAuthenticationServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class AppleAuthenticationServiceGraph {
    public init() { }

    @Provide
    private func makeAppleAuthenticationService() -> AppleAuthenticationService {
        AppleAuthenticationServiceImpl()
    }
}
