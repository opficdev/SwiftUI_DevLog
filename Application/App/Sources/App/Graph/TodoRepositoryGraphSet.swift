//
//  TodoRepositoryGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Infra
import Persistence
import Widget

final class TodoRepositoryGraphSet {
    let todoMutationEventBusGraph = TodoMutationEventBusGraph()
    let todoRepositoryGraph: TodoRepositoryGraph
    let todoCategoryRepositoryGraph: TodoCategoryRepositoryGraph
    let widgetTodoSnapshotRepositoryGraph: WidgetTodoSnapshotRepositoryGraph

    init(
        todoQueryServiceGraph: TodoQueryServiceGraph,
        todoCommandServiceGraph: TodoCommandServiceGraph,
        todoCategoryServiceGraph: TodoCategoryServiceGraph,
        memoryCacheStoreGraph: MemoryCacheStoreGraph,
        widgetSnapshotUpdaterGraph: WidgetSnapshotUpdaterGraph
    ) {
        self.todoRepositoryGraph = TodoRepositoryGraph(
            input: TodoRepositoryGraphInput(
                queryService: todoQueryServiceGraph.todoQueryService,
                commandService: todoCommandServiceGraph.todoCommandService,
                todoCategoryService: todoCategoryServiceGraph.todoCategoryService,
                store: memoryCacheStoreGraph.memoryCacheStore,
                updater: widgetSnapshotUpdaterGraph.widgetSnapshotUpdater,
                eventBus: todoMutationEventBusGraph.todoMutationEventBus
            )
        )
        self.todoCategoryRepositoryGraph = TodoCategoryRepositoryGraph(
            input: TodoCategoryRepositoryGraphInput(
                todoCategoryService: todoCategoryServiceGraph.todoCategoryService,
                store: memoryCacheStoreGraph.memoryCacheStore
            )
        )
        self.widgetTodoSnapshotRepositoryGraph = WidgetTodoSnapshotRepositoryGraph(
            input: WidgetTodoSnapshotRepositoryGraphInput(
                queryService: todoQueryServiceGraph.todoQueryService
            )
        )
    }
}
