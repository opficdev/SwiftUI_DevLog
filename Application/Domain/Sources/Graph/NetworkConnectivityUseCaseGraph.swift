//
//  NetworkConnectivityUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct NetworkConnectivityUseCaseGraphInput {
    public let repository: NetworkConnectivityRepository

    public init(repository: NetworkConnectivityRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: NetworkConnectivityUseCaseGraphInput.self)
public final class NetworkConnectivityUseCaseGraph {
    @Provide
    private func makeObserveNetworkConnectivityUseCase() -> ObserveNetworkConnectivityUseCase {
        ObserveNetworkConnectivityUseCaseImpl(input.repository)
    }
}
