//
//  PersistenceGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Persistence

final class PersistenceGraphSet {
    let userDefaultsStoreGraph = UserDefaultsStoreGraph()
    let memoryCacheStoreGraph = MemoryCacheStoreGraph()
    let themeStoreGraph = ThemeStoreGraph()
}
