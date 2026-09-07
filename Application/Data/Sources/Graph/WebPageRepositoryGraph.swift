//
//  WebPageRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct WebPageRepositoryGraphInput {
    public let authService: AuthService
    public let metadataService: WebPageMetadataService
    public let webPageService: WebPageService

    public init(
        authService: AuthService,
        metadataService: WebPageMetadataService,
        webPageService: WebPageService
    ) {
        self.authService = authService
        self.metadataService = metadataService
        self.webPageService = webPageService
    }
}

@DependencyGraph(input: WebPageRepositoryGraphInput.self)
public final class WebPageRepositoryGraph {
    @Provide
    private func makeWebPageRepository() -> WebPageRepository {
        WebPageRepositoryImpl(
            authService: input.authService,
            metadataService: input.metadataService,
            webPageService: input.webPageService
        )
    }
}
