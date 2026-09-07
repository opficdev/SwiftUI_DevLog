//
//  AuthSessionUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct AuthSessionUseCaseGraphInput {
    public let repository: AuthSessionRepository

    public init(repository: AuthSessionRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: AuthSessionUseCaseGraphInput.self)
public final class AuthSessionUseCaseGraph {
    @Provide
    private func makeObserveAuthSessionUseCase() -> ObserveAuthSessionUseCase {
        ObserveAuthSessionUseCaseImpl(input.repository)
    }
}
