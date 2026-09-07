//
//  PushNotificationUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct PushNotificationUseCaseGraphInput {
    public let repository: PushNotificationRepository

    public init(repository: PushNotificationRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: PushNotificationUseCaseGraphInput.self)
public final class PushNotificationUseCaseGraph {
    @Provide
    private func makeFetchPushSettingsUseCase() -> FetchPushSettingsUseCase {
        FetchPushSettingsUseCaseImpl(input.repository)
    }

    @Provide
    private func makeUpdatePushSettingsUseCase() -> UpdatePushSettingsUseCase {
        UpdatePushSettingsUseCaseImpl(input.repository)
    }

    @Provide
    private func makeDeletePushNotificationUseCase() -> DeletePushNotificationUseCase {
        DeletePushNotificationUseCaseImpl(input.repository)
    }

    @Provide
    private func makeUndoDeletePushNotificationUseCase() -> UndoDeletePushNotificationUseCase {
        UndoDeletePushNotificationUseCaseImpl(input.repository)
    }

    @Provide
    private func makeFetchPushNotificationsUseCase() -> FetchPushNotificationsUseCase {
        FetchPushNotificationsUseCaseImpl(input.repository)
    }

    @Provide
    private func makeObserveUnreadPushCountUseCase() -> ObserveUnreadPushCountUseCase {
        ObserveUnreadPushCountUseCaseImpl(input.repository)
    }

    @Provide
    private func makeTogglePushNotificationReadUseCase() -> TogglePushNotificationReadUseCase {
        TogglePushNotificationReadUseCaseImpl(input.repository)
    }
}
