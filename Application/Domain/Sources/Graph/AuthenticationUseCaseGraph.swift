//
//  AuthenticationUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct AuthenticationUseCaseGraphInput {
    public let repository: AuthenticationRepository

    public init(repository: AuthenticationRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: AuthenticationUseCaseGraphInput.self)
public final class AuthenticationUseCaseGraph {
    @Provide
    private func makeSignInUseCase() -> SignInUseCase {
        SignInUseCaseImpl(input.repository)
    }

    @Provide
    private func makeSignOutUseCase() -> SignOutUseCase {
        SignOutUseCaseImpl(input.repository)
    }

    @Provide
    private func makeDeleteAuthUseCase() -> DeleteAuthUseCase {
        DeleteAuthUseCaseImpl(input.repository)
    }
}
