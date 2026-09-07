//
//  NWPathConnectivityProviderGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class NWPathConnectivityProviderGraph {
    public init() { }

    @Provide(.lazy)
    private func makeNWPathConnectivityProvider() -> NWPathConnectivityProvider {
        NWPathConnectivityProviderImpl()
    }
}
