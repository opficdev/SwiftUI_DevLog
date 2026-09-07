//
//  WebPageRepositoryGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Infra
import Persistence

final class WebPageRepositoryGraphSet {
    let webPageRepositoryGraph: WebPageRepositoryGraph
    let webPageImageRepositoryGraph: WebPageImageRepositoryGraph

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
    }
}
