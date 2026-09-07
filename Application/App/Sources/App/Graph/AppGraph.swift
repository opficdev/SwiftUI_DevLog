//
//  AppGraph.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Cradle

@MainActor
@DependencyGraph(.shared)
final class AppGraph {
    @Provide
    private func makePersistenceGraphSet() -> PersistenceGraphSet {
        PersistenceGraphSet()
    }

    @Provide
    private func makeInfraGraphSet(
        persistenceGraphSet: PersistenceGraphSet
    ) -> InfraGraphSet {
        InfraGraphSet(
            webPageImageStore: persistenceGraphSet.webPageImageStoreGraph.webPageImageStore
        )
    }

    @Provide
    private func makeWidgetGraphSet() -> WidgetGraphSet {
        WidgetGraphSet()
    }

    @Provide
    private func makeDevelopmentGraphSet(
        infraGraphSet: InfraGraphSet
    ) -> DevelopmentGraphSet {
        DevelopmentGraphSet(
            developmentGoalServiceGraph: infraGraphSet.developmentGoalServiceGraph,
            developmentRecordServiceGraph: infraGraphSet.developmentRecordServiceGraph
        )
    }

    @Provide
    private func makeAuthenticationGraphSet(
        persistenceGraphSet: PersistenceGraphSet,
        infraGraphSet: InfraGraphSet,
        widgetGraphSet: WidgetGraphSet
    ) -> AuthenticationGraphSet {
        AuthenticationGraphSet(
            authServiceGraph: infraGraphSet.authServiceGraph,
            appleAuthenticationServiceGraph: infraGraphSet.appleAuthenticationServiceGraph,
            githubAuthenticationServiceGraph: infraGraphSet.githubAuthenticationServiceGraph,
            googleAuthenticationServiceGraph: infraGraphSet.googleAuthenticationServiceGraph,
            userServiceGraph: infraGraphSet.userServiceGraph,
            todoCategoryServiceGraph: infraGraphSet.todoCategoryServiceGraph,
            memoryCacheStoreGraph: persistenceGraphSet.memoryCacheStoreGraph,
            widgetSnapshotUpdaterGraph: widgetGraphSet.widgetSnapshotUpdaterGraph,
            authSessionStateProviderGraph: widgetGraphSet.authSessionStateProviderGraph
        )
    }

    @Provide
    private func makeTodoGraphSet(
        persistenceGraphSet: PersistenceGraphSet,
        infraGraphSet: InfraGraphSet,
        widgetGraphSet: WidgetGraphSet,
        developmentGraphSet: DevelopmentGraphSet
    ) -> TodoGraphSet {
        TodoGraphSet(
            todoQueryServiceGraph: infraGraphSet.todoQueryServiceGraph,
            todoCommandServiceGraph: infraGraphSet.todoCommandServiceGraph,
            todoCategoryServiceGraph: infraGraphSet.todoCategoryServiceGraph,
            memoryCacheStoreGraph: persistenceGraphSet.memoryCacheStoreGraph,
            widgetSnapshotUpdaterGraph: widgetGraphSet.widgetSnapshotUpdaterGraph,
            developmentGoalRepositoryGraph: developmentGraphSet.developmentGoalRepositoryGraph
        )
    }

    @Provide
    private func makeWebPageGraphSet(
        persistenceGraphSet: PersistenceGraphSet,
        infraGraphSet: InfraGraphSet
    ) -> WebPageGraphSet {
        WebPageGraphSet(
            authServiceGraph: infraGraphSet.authServiceGraph,
            webPageMetadataServiceGraph: infraGraphSet.webPageMetadataServiceGraph,
            webPageServiceGraph: infraGraphSet.webPageServiceGraph,
            webPageImageStoreGraph: persistenceGraphSet.webPageImageStoreGraph
        )
    }

    @Provide
    private func makeUserProfileGraphSet(
        persistenceGraphSet: PersistenceGraphSet,
        infraGraphSet: InfraGraphSet
    ) -> UserProfileGraphSet {
        UserProfileGraphSet(
            userServiceGraph: infraGraphSet.userServiceGraph,
            profileImageDataServiceGraph: infraGraphSet.profileImageDataServiceGraph,
            memoryCacheStoreGraph: persistenceGraphSet.memoryCacheStoreGraph
        )
    }

    @Provide
    private func makePushNotificationGraphSet(
        persistenceGraphSet: PersistenceGraphSet,
        infraGraphSet: InfraGraphSet
    ) -> PushNotificationGraphSet {
        PushNotificationGraphSet(
            pushNotificationServiceGraph: infraGraphSet.pushNotificationServiceGraph,
            todoCategoryServiceGraph: infraGraphSet.todoCategoryServiceGraph,
            memoryCacheStoreGraph: persistenceGraphSet.memoryCacheStoreGraph
        )
    }

    @Provide
    private func makeUserPreferencesGraphSet(
        persistenceGraphSet: PersistenceGraphSet,
        widgetGraphSet: WidgetGraphSet
    ) -> UserPreferencesGraphSet {
        UserPreferencesGraphSet(
            userDefaultsStoreGraph: persistenceGraphSet.userDefaultsStoreGraph,
            themeStoreGraph: persistenceGraphSet.themeStoreGraph,
            widgetSnapshotPreferenceStoreGraph: widgetGraphSet.widgetSnapshotPreferenceStoreGraph,
            widgetSyncEventBusGraph: widgetGraphSet.widgetSyncEventBusGraph
        )
    }

    @Provide
    private func makeAnalyticsGraphSet(
        infraGraphSet: InfraGraphSet
    ) -> AnalyticsGraphSet {
        AnalyticsGraphSet(
            analyticsServiceGraph: infraGraphSet.analyticsServiceGraph
        )
    }

    @Provide
    private func makeAppUpdateGraphSet(
        infraGraphSet: InfraGraphSet
    ) -> AppUpdateGraphSet {
        AppUpdateGraphSet(
            appStoreVersionServiceGraph: infraGraphSet.appStoreVersionServiceGraph
        )
    }

    @Provide
    private func makeNetworkConnectivityGraphSet(
        infraGraphSet: InfraGraphSet
    ) -> NetworkConnectivityGraphSet {
        NetworkConnectivityGraphSet(
            networkConnectivityProviderGraph: infraGraphSet.networkConnectivityProviderGraph
        )
    }
}
