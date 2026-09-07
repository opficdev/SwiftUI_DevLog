//
//  WidgetSyncEventBusGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class WidgetSyncEventBusGraph {
    public init() { }

    @Provide
    private func makeWidgetSyncEventBus() -> WidgetSyncEventBus {
        WidgetSyncEventBusImpl()
    }
}
