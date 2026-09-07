//
//  AuthSessionStateProviderGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class AuthSessionStateProviderGraph {
    public init() { }

    @Provide
    private func makeAuthSessionStateProvider() -> AuthSessionStateProvider {
        AuthSessionStateProviderImpl()
    }
}
