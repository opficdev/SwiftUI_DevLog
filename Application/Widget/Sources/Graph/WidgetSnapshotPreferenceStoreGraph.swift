//
//  WidgetSnapshotPreferenceStoreGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class WidgetSnapshotPreferenceStoreGraph {
    public init() { }

    @Provide
    private func makeWidgetSnapshotPreferenceStore() -> WidgetSnapshotPreferenceStore {
        WidgetSnapshotPreferenceStoreImpl()
    }
}
