//
//  LifecycleGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Infra
import Widget

final class LifecycleGraphSet {
    let fcmTokenSyncHandlerGraph: FCMTokenSyncHandlerGraph
    let userTimeZoneSyncHandlerGraph: UserTimeZoneSyncHandlerGraph
    let widgetSyncEventHandlerGraph: WidgetSyncEventHandlerGraph
    let widgetSessionSyncHandlerGraph: WidgetSessionSyncHandlerGraph
    let pushNotificationOpenHandlerGraph: PushNotificationOpenHandlerGraph

    init(
        authServiceGraph: AuthServiceGraph,
        pushMessagingServiceGraph: PushMessagingServiceGraph,
        userServiceGraph: UserServiceGraph,
        analyticsServiceGraph: AnalyticsServiceGraph,
        widgetSyncEventBusGraph: WidgetSyncEventBusGraph,
        widgetTodoSnapshotRepositoryGraph: WidgetTodoSnapshotRepositoryGraph,
        widgetSnapshotUpdaterGraph: WidgetSnapshotUpdaterGraph,
        authSessionStateProviderGraph: AuthSessionStateProviderGraph
    ) {
        self.fcmTokenSyncHandlerGraph = FCMTokenSyncHandlerGraph(
            input: FCMTokenSyncHandlerGraphInput(
                authService: authServiceGraph.authService,
                messagingService: pushMessagingServiceGraph.pushMessagingService,
                userService: userServiceGraph.userService
            )
        )
        self.userTimeZoneSyncHandlerGraph = UserTimeZoneSyncHandlerGraph(
            input: UserTimeZoneSyncHandlerGraphInput(
                authService: authServiceGraph.authService,
                userService: userServiceGraph.userService
            )
        )
        self.widgetSyncEventHandlerGraph = WidgetSyncEventHandlerGraph(
            input: WidgetSyncEventHandlerGraphInput(
                eventBus: widgetSyncEventBusGraph.widgetSyncEventBus,
                repository: widgetTodoSnapshotRepositoryGraph.widgetTodoSnapshotRepository,
                snapshotUpdater: widgetSnapshotUpdaterGraph.widgetSnapshotUpdater
            )
        )
        self.widgetSessionSyncHandlerGraph = WidgetSessionSyncHandlerGraph(
            input: WidgetSessionSyncHandlerGraphInput(
                provider: authSessionStateProviderGraph.authSessionStateProvider,
                widgetSyncEventBus: widgetSyncEventBusGraph.widgetSyncEventBus
            )
        )
        self.pushNotificationOpenHandlerGraph = PushNotificationOpenHandlerGraph(
            input: PushNotificationOpenHandlerGraphInput(
                analyticsService: analyticsServiceGraph.analyticsService
            )
        )
    }
}
