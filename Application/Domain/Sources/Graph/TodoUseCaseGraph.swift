//
//  TodoUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct TodoUseCaseGraphInput {
    public let repository: TodoRepository

    public init(repository: TodoRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: TodoUseCaseGraphInput.self)
public final class TodoUseCaseGraph {
    @Provide
    private func makeFetchTodoByIdUseCase() -> FetchTodoByIdUseCase {
        FetchTodoByIdUseCaseImpl(input.repository)
    }

    @Provide
    private func makeFetchReferenceItemsUseCase() -> FetchReferenceItemsUseCase {
        FetchReferenceItemsUseCaseImpl(input.repository)
    }

    @Provide
    private func makeFetchTodosUseCase() -> FetchTodosUseCase {
        FetchTodosUseCaseImpl(input.repository)
    }

    @Provide
    private func makeUpsertTodoUseCase() -> UpsertTodoUseCase {
        UpsertTodoUseCaseImpl(input.repository)
    }

    @Provide
    private func makeDeleteTodoUseCase() -> DeleteTodoUseCase {
        DeleteTodoUseCaseImpl(input.repository)
    }

    @Provide
    private func makeUndoDeleteTodoUseCase() -> UndoDeleteTodoUseCase {
        UndoDeleteTodoUseCaseImpl(input.repository)
    }
}
