//
//  WidgetSnapshotUpdaterGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data
import WidgetCore

public struct WidgetSnapshotUpdaterGraphInput {
    public let snapshotStore: WidgetSnapshotStore
    public let preferenceStore: WidgetSnapshotPreferenceStore

    public init(
        snapshotStore: WidgetSnapshotStore,
        preferenceStore: WidgetSnapshotPreferenceStore
    ) {
        self.snapshotStore = snapshotStore
        self.preferenceStore = preferenceStore
    }
}

@DependencyGraph(input: WidgetSnapshotUpdaterGraphInput.self)
public final class WidgetSnapshotUpdaterGraph {
    @Provide
    private func makeWidgetSnapshotUpdater() -> WidgetSnapshotUpdater {
        WidgetSnapshotUpdaterImpl(
            snapshotStore: input.snapshotStore,
            preferenceStore: input.preferenceStore
        )
    }
}
