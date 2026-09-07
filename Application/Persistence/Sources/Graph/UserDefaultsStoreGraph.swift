//
//  UserDefaultsStoreGraph.swift
//  Persistence
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class UserDefaultsStoreGraph {
    public init() { }

    @Provide
    private func makeUserDefaultsStore() -> UserDefaultsStore {
        UserDefaultsStoreImpl()
    }
}
