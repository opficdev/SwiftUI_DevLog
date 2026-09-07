//
//  WidgetSnapshotStoreGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import WidgetCore

public struct WidgetSnapshotStoreGraphInput {
    public let store: WidgetSharedDefaultsStore

    public init(store: WidgetSharedDefaultsStore) {
        self.store = store
    }
}

@DependencyGraph(input: WidgetSnapshotStoreGraphInput.self)
public final class WidgetSnapshotStoreGraph {
    @Provide
    private func makeWidgetSnapshotStore() -> WidgetSnapshotStore {
        WidgetSnapshotStore(store: input.store)
    }
}
