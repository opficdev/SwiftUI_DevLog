//
//  PushNotificationDependencyPreparation.swift
//  NotificationTab
//
//  Created by opfic on 9/7/26.
//

import Domain
import PresentationShared

public enum PushNotificationDependencyPreparation {
    public static func prepareQuery(
        _ dependencies: inout DependencyValues,
        fetchQueryUseCase: FetchPushNotificationQueryUseCase,
        updateQueryUseCase: UpdatePushNotificationQueryUseCase
    ) {
        dependencies.fetchPushNotificationQueryUseCase = fetchQueryUseCase
        dependencies.updatePushNotificationQueryUseCase = updateQueryUseCase
    }

    public static func prepareList(
        _ dependencies: inout DependencyValues,
        fetchNotificationsUseCase: FetchPushNotificationsUseCase,
        deleteNotificationUseCase: DeletePushNotificationUseCase,
        undoDeleteNotificationUseCase: UndoDeletePushNotificationUseCase
    ) {
        dependencies.fetchPushNotificationsUseCase = fetchNotificationsUseCase
        dependencies.deletePushNotificationUseCase = deleteNotificationUseCase
        dependencies.undoDeletePushNotificationUseCase = undoDeleteNotificationUseCase
    }

    public static func prepareReadState(
        _ dependencies: inout DependencyValues,
        toggleNotificationReadUseCase: TogglePushNotificationReadUseCase
    ) {
        dependencies.togglePushNotificationReadUseCase = toggleNotificationReadUseCase
    }
}

extension DependencyValues {
    var fetchPushNotificationQueryUseCase: FetchPushNotificationQueryUseCase {
        get { self[FetchPushNotificationQueryUseCaseKey.self] }
        set { self[FetchPushNotificationQueryUseCaseKey.self] = newValue }
    }
}

private enum FetchPushNotificationQueryUseCaseKey: DependencyKey {
    static var liveValue: FetchPushNotificationQueryUseCase {
        preconditionFailure("FetchPushNotificationQueryUseCase must be provided.")
    }
}
