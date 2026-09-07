//
//  WidgetGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Widget

final class WidgetGraphSet {
    let authSessionStateProviderGraph = AuthSessionStateProviderGraph()
    let widgetSyncEventBusGraph = WidgetSyncEventBusGraph()
    let widgetSharedDefaultsStoreGraph = WidgetSharedDefaultsStoreGraph()
    let widgetSnapshotPreferenceStoreGraph = WidgetSnapshotPreferenceStoreGraph()
    let widgetSnapshotStoreGraph: WidgetSnapshotStoreGraph
    let widgetSnapshotUpdaterGraph: WidgetSnapshotUpdaterGraph

    init() {
        self.widgetSnapshotStoreGraph = WidgetSnapshotStoreGraph(
            input: WidgetSnapshotStoreGraphInput(
                store: widgetSharedDefaultsStoreGraph.widgetSharedDefaultsStore
            )
        )
        self.widgetSnapshotUpdaterGraph = WidgetSnapshotUpdaterGraph(
            input: WidgetSnapshotUpdaterGraphInput(
                snapshotStore: widgetSnapshotStoreGraph.widgetSnapshotStore,
                preferenceStore: widgetSnapshotPreferenceStoreGraph.widgetSnapshotPreferenceStore
            )
        )
    }
}
