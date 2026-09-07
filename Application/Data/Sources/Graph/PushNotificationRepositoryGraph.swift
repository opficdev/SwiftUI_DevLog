//
//  PushNotificationRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct PushNotificationRepositoryGraphInput {
    public let pushNotificationService: PushNotificationService
    public let todoCategoryService: TodoCategoryService
    public let store: MemoryCacheStore

    public init(
        pushNotificationService: PushNotificationService,
        todoCategoryService: TodoCategoryService,
        store: MemoryCacheStore
    ) {
        self.pushNotificationService = pushNotificationService
        self.todoCategoryService = todoCategoryService
        self.store = store
    }
}

@DependencyGraph(input: PushNotificationRepositoryGraphInput.self)
public final class PushNotificationRepositoryGraph {
    @Provide
    private func makePushNotificationRepository() -> PushNotificationRepository {
        PushNotificationRepositoryImpl(
            pushNotificationService: input.pushNotificationService,
            todoCategoryService: input.todoCategoryService,
            store: input.store
        )
    }
}
