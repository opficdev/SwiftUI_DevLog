//
//  TodoGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra
import Persistence
import Widget

final class TodoGraphSet {
    let todoMutationEventBusGraph = TodoMutationEventBusGraph()
    let todoRepositoryGraph: TodoRepositoryGraph
    let todoCategoryRepositoryGraph: TodoCategoryRepositoryGraph
    let widgetTodoSnapshotRepositoryGraph: WidgetTodoSnapshotRepositoryGraph
    let todoUseCaseGraph: TodoUseCaseGraph
    let todoCategoryUseCaseGraph: TodoCategoryUseCaseGraph
    let todoGoalUseCaseGraph: TodoGoalUseCaseGraph

    init(
        todoQueryServiceGraph: TodoQueryServiceGraph,
        todoCommandServiceGraph: TodoCommandServiceGraph,
        todoCategoryServiceGraph: TodoCategoryServiceGraph,
        memoryCacheStoreGraph: MemoryCacheStoreGraph,
        widgetSnapshotUpdaterGraph: WidgetSnapshotUpdaterGraph,
        developmentGoalRepositoryGraph: DevelopmentGoalRepositoryGraph
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
        self.todoUseCaseGraph = TodoUseCaseGraph(
            input: TodoUseCaseGraphInput(
                repository: todoRepositoryGraph.todoRepository
            )
        )
        self.todoCategoryUseCaseGraph = TodoCategoryUseCaseGraph(
            input: TodoCategoryUseCaseGraphInput(
                todoCategoryRepository: todoCategoryRepositoryGraph.todoCategoryRepository
            )
        )
        self.todoGoalUseCaseGraph = TodoGoalUseCaseGraph(
            input: TodoGoalUseCaseGraphInput(
                todoRepository: todoRepositoryGraph.todoRepository,
                goalRepository: developmentGoalRepositoryGraph.developmentGoalRepository
            )
        )
    }
}
