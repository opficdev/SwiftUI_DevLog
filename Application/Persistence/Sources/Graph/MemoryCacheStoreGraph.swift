//
//  MemoryCacheStoreGraph.swift
//  Persistence
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class MemoryCacheStoreGraph {
    public init() { }

    @Provide
    private func makeMemoryCacheStore() -> MemoryCacheStore {
        MemoryCacheStoreImpl()
    }
}
