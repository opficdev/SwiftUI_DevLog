//
//  WidgetSharedDefaultsStoreGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import WidgetCore

@DependencyGraph
public final class WidgetSharedDefaultsStoreGraph {
    public init() { }

    @Provide
    private func makeWidgetSharedDefaultsStore() -> WidgetSharedDefaultsStore {
        WidgetSharedDefaultsStore()
    }
}
