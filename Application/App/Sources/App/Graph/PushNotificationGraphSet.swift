//
//  PushNotificationGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra
import Persistence

final class PushNotificationGraphSet {
    let pushNotificationRepositoryGraph: PushNotificationRepositoryGraph
    let pushNotificationUseCaseGraph: PushNotificationUseCaseGraph

    init(
        pushNotificationServiceGraph: PushNotificationServiceGraph,
        todoCategoryServiceGraph: TodoCategoryServiceGraph,
        memoryCacheStoreGraph: MemoryCacheStoreGraph
    ) {
        self.pushNotificationRepositoryGraph = PushNotificationRepositoryGraph(
            input: PushNotificationRepositoryGraphInput(
                pushNotificationService: pushNotificationServiceGraph.pushNotificationService,
                todoCategoryService: todoCategoryServiceGraph.todoCategoryService,
                store: memoryCacheStoreGraph.memoryCacheStore
            )
        )
        self.pushNotificationUseCaseGraph = PushNotificationUseCaseGraph(
            input: PushNotificationUseCaseGraphInput(
                repository: pushNotificationRepositoryGraph.pushNotificationRepository
            )
        )
    }
}
