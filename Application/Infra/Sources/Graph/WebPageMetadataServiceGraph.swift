//
//  WebPageMetadataServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

public struct WebPageMetadataServiceGraphInput {
    public let webPageImageStore: WebPageImageStore

    public init(webPageImageStore: WebPageImageStore) {
        self.webPageImageStore = webPageImageStore
    }
}

@DependencyGraph(input: WebPageMetadataServiceGraphInput.self)
public final class WebPageMetadataServiceGraph {
    @Provide
    private func makeWebPageMetadataService() -> WebPageMetadataService {
        WebPageMetadataServiceImpl(store: input.webPageImageStore)
    }
}
