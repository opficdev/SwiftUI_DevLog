//
//  UserPreferencesRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct UserPreferencesRepositoryGraphInput {
    public let store: UserDefaultsStore
    public let themeStore: ThemeStore
    public let widgetSnapshotPreferenceStore: WidgetSnapshotPreferenceStore
    public let widgetSyncEventBus: WidgetSyncEventBus

    public init(
        store: UserDefaultsStore,
        themeStore: ThemeStore,
        widgetSnapshotPreferenceStore: WidgetSnapshotPreferenceStore,
        widgetSyncEventBus: WidgetSyncEventBus
    ) {
        self.store = store
        self.themeStore = themeStore
        self.widgetSnapshotPreferenceStore = widgetSnapshotPreferenceStore
        self.widgetSyncEventBus = widgetSyncEventBus
    }
}

@DependencyGraph(input: UserPreferencesRepositoryGraphInput.self)
public final class UserPreferencesRepositoryGraph {
    @Provide
    private func makeUserPreferencesRepository() -> UserPreferencesRepository {
        UserPreferencesRepositoryImpl(
            store: input.store,
            themeStore: input.themeStore,
            widgetSnapshotPreferenceStore: input.widgetSnapshotPreferenceStore,
            widgetSyncEventBus: input.widgetSyncEventBus
        )
    }
}
