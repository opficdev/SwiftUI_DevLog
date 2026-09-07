//
//  TodoGoalUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct TodoGoalUseCaseGraphInput {
    public let todoRepository: TodoRepository
    public let goalRepository: DevelopmentGoalRepository

    public init(
        todoRepository: TodoRepository,
        goalRepository: DevelopmentGoalRepository
    ) {
        self.todoRepository = todoRepository
        self.goalRepository = goalRepository
    }
}

@DependencyGraph(input: TodoGoalUseCaseGraphInput.self)
public final class TodoGoalUseCaseGraph {
    @Provide
    private func makeUpdateTodoGoalUseCase() -> UpdateTodoGoalUseCase {
        UpdateTodoGoalUseCaseImpl(input.todoRepository, input.goalRepository)
    }
}
