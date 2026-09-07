//
//  NetworkConnectivityRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct NetworkConnectivityRepositoryGraphInput {
    public let connectivityProvider: NWPathConnectivityProvider

    public init(connectivityProvider: NWPathConnectivityProvider) {
        self.connectivityProvider = connectivityProvider
    }
}

@DependencyGraph(input: NetworkConnectivityRepositoryGraphInput.self)
public final class NetworkConnectivityRepositoryGraph {
    @Provide(.lazy)
    private func makeNetworkConnectivityRepository() -> NetworkConnectivityRepository {
        NetworkConnectivityRepositoryImpl(
            connectivityProvider: input.connectivityProvider
        )
    }
}
