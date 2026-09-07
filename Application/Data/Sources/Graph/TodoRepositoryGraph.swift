//
//  TodoRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct TodoRepositoryGraphInput {
    public let queryService: TodoQueryService
    public let commandService: TodoCommandService
    public let todoCategoryService: TodoCategoryService
    public let store: MemoryCacheStore
    public let updater: WidgetSnapshotUpdater
    public let eventBus: TodoMutationEventBus

    public init(
        queryService: TodoQueryService,
        commandService: TodoCommandService,
        todoCategoryService: TodoCategoryService,
        store: MemoryCacheStore,
        updater: WidgetSnapshotUpdater,
        eventBus: TodoMutationEventBus
    ) {
        self.queryService = queryService
        self.commandService = commandService
        self.todoCategoryService = todoCategoryService
        self.store = store
        self.updater = updater
        self.eventBus = eventBus
    }
}

@DependencyGraph(input: TodoRepositoryGraphInput.self)
public final class TodoRepositoryGraph {
    @Provide
    private func makeTodoRepository() -> TodoRepository {
        TodoRepositoryImpl(
            queryService: input.queryService,
            commandService: input.commandService,
            todoCategoryService: input.todoCategoryService,
            store: input.store,
            updater: input.updater,
            eventBus: input.eventBus
        )
    }
}
