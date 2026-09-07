//
//  TodoCategoryUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct TodoCategoryUseCaseGraphInput {
    public let todoCategoryRepository: TodoCategoryRepository

    public init(todoCategoryRepository: TodoCategoryRepository) {
        self.todoCategoryRepository = todoCategoryRepository
    }
}

@DependencyGraph(input: TodoCategoryUseCaseGraphInput.self)
public final class TodoCategoryUseCaseGraph {
    @Provide
    private func makeFetchTodoCategoryPreferencesUseCase() -> FetchTodoCategoryPreferencesUseCase {
        FetchTodoCategoryPreferencesUseCaseImpl(input.todoCategoryRepository)
    }

    @Provide
    private func makeUpdateTodoCategoryPreferencesUseCase() -> UpdateTodoCategoryPreferencesUseCase {
        UpdateTodoCategoryPreferencesUseCaseImpl(input.todoCategoryRepository)
    }
}
