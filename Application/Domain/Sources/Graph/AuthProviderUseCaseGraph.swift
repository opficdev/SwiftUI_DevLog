//
//  AuthProviderUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct AuthProviderUseCaseGraphInput {
    public let repository: AuthDataRepository

    public init(repository: AuthDataRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: AuthProviderUseCaseGraphInput.self)
public final class AuthProviderUseCaseGraph {
    @Provide
    private func makeFetchAuthProvidersUseCase() -> FetchAuthProvidersUseCase {
        FetchAuthProvidersUseCaseImpl(input.repository)
    }

    @Provide
    private func makeLinkAuthProviderUseCase() -> LinkAuthProviderUseCase {
        LinkAuthProviderUseCaseImpl(input.repository)
    }

    @Provide
    private func makeUnlinkAuthProviderUseCase() -> UnlinkAuthProviderUseCase {
        UnlinkAuthProviderUseCaseImpl(input.repository)
    }
}
