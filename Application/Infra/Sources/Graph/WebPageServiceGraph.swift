//
//  WebPageServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class WebPageServiceGraph {
    public init() { }

    @Provide
    private func makeWebPageService() -> WebPageService {
        WebPageServiceImpl()
    }
}
