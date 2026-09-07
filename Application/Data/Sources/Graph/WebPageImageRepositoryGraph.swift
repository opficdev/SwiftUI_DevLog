//
//  WebPageImageRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct WebPageImageRepositoryGraphInput {
    public let authService: AuthService
    public let store: WebPageImageStore

    public init(
        authService: AuthService,
        store: WebPageImageStore
    ) {
        self.authService = authService
        self.store = store
    }
}

@DependencyGraph(input: WebPageImageRepositoryGraphInput.self)
public final class WebPageImageRepositoryGraph {
    @Provide
    private func makeWebPageImageRepository() -> WebPageImageRepository {
        WebPageImageRepositoryImpl(
            authService: input.authService,
            store: input.store
        )
    }
}
