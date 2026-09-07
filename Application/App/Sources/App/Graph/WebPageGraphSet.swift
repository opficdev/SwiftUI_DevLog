//
//  WebPageGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra
import Persistence

final class WebPageGraphSet {
    let webPageRepositoryGraph: WebPageRepositoryGraph
    let webPageImageRepositoryGraph: WebPageImageRepositoryGraph
    let webPageUseCaseGraph: WebPageUseCaseGraph
    let webPageImageUseCaseGraph: WebPageImageUseCaseGraph

    init(
        authServiceGraph: AuthServiceGraph,
        webPageMetadataServiceGraph: WebPageMetadataServiceGraph,
        webPageServiceGraph: WebPageServiceGraph,
        webPageImageStoreGraph: WebPageImageStoreGraph
    ) {
        self.webPageRepositoryGraph = WebPageRepositoryGraph(
            input: WebPageRepositoryGraphInput(
                authService: authServiceGraph.authService,
                metadataService: webPageMetadataServiceGraph.webPageMetadataService,
                webPageService: webPageServiceGraph.webPageService
            )
        )
        self.webPageImageRepositoryGraph = WebPageImageRepositoryGraph(
            input: WebPageImageRepositoryGraphInput(
                authService: authServiceGraph.authService,
                store: webPageImageStoreGraph.webPageImageStore
            )
        )
        self.webPageUseCaseGraph = WebPageUseCaseGraph(
            input: WebPageUseCaseGraphInput(
                repository: webPageRepositoryGraph.webPageRepository
            )
        )
        self.webPageImageUseCaseGraph = WebPageImageUseCaseGraph(
            input: WebPageImageUseCaseGraphInput(
                repository: webPageImageRepositoryGraph.webPageImageRepository
            )
        )
    }
}
