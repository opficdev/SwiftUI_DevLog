//
//  UserPreferencesGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Persistence
import Widget

final class UserPreferencesGraphSet {
    let userPreferencesRepositoryGraph: UserPreferencesRepositoryGraph
    let userPreferencesUseCaseGraph: UserPreferencesUseCaseGraph

    init(
        userDefaultsStoreGraph: UserDefaultsStoreGraph,
        themeStoreGraph: ThemeStoreGraph,
        widgetSnapshotPreferenceStoreGraph: WidgetSnapshotPreferenceStoreGraph,
        widgetSyncEventBusGraph: WidgetSyncEventBusGraph
    ) {
        self.userPreferencesRepositoryGraph = UserPreferencesRepositoryGraph(
            input: UserPreferencesRepositoryGraphInput(
                store: userDefaultsStoreGraph.userDefaultsStore,
                themeStore: themeStoreGraph.themeStore,
                widgetSnapshotPreferenceStore: widgetSnapshotPreferenceStoreGraph.widgetSnapshotPreferenceStore,
                widgetSyncEventBus: widgetSyncEventBusGraph.widgetSyncEventBus
            )
        )
        self.userPreferencesUseCaseGraph = UserPreferencesUseCaseGraph(
            input: UserPreferencesUseCaseGraphInput(
                repository: userPreferencesRepositoryGraph.userPreferencesRepository
            )
        )
    }
}
