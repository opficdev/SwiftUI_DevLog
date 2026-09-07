//
//  TodoCategoryRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct TodoCategoryRepositoryGraphInput {
    public let todoCategoryService: TodoCategoryService
    public let store: MemoryCacheStore

    public init(
        todoCategoryService: TodoCategoryService,
        store: MemoryCacheStore
    ) {
        self.todoCategoryService = todoCategoryService
        self.store = store
    }
}

@DependencyGraph(input: TodoCategoryRepositoryGraphInput.self)
public final class TodoCategoryRepositoryGraph {
    @Provide
    private func makeTodoCategoryRepository() -> TodoCategoryRepository {
        TodoCategoryRepositoryImpl(
            todoCategoryService: input.todoCategoryService,
            store: input.store
        )
    }
}
