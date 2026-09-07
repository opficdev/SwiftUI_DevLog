//
//  AppStoreVersionServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class AppStoreVersionServiceGraph {
    public init() { }

    @Provide
    private func makeAppStoreVersionService() -> AppStoreVersionService {
        ITunesAppVersionServiceImpl()
    }
}
