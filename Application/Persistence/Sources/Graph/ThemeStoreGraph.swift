//
//  ThemeStoreGraph.swift
//  Persistence
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class ThemeStoreGraph {
    public init() { }

    @Provide
    private func makeThemeStore() -> ThemeStore {
        ThemeStoreImpl()
    }
}
