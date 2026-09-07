//
//  NetworkConnectivityGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra

final class NetworkConnectivityGraphSet {
    private let networkConnectivityProviderGraph: NWPathConnectivityProviderGraph
    private(set) lazy var networkConnectivityRepositoryGraph = NetworkConnectivityRepositoryGraph(
        input: NetworkConnectivityRepositoryGraphInput(
            connectivityProvider: networkConnectivityProviderGraph.nwPathConnectivityProvider
        )
    )
    private(set) lazy var networkConnectivityUseCaseGraph = NetworkConnectivityUseCaseGraph(
        input: NetworkConnectivityUseCaseGraphInput(
            repository: networkConnectivityRepositoryGraph.networkConnectivityRepository
        )
    )

    init(networkConnectivityProviderGraph: NWPathConnectivityProviderGraph) {
        self.networkConnectivityProviderGraph = networkConnectivityProviderGraph
    }
}
