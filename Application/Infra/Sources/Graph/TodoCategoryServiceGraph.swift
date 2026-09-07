//
//  TodoCategoryServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class TodoCategoryServiceGraph {
    public init() { }

    @Provide
    private func makeTodoCategoryService() -> TodoCategoryService {
        TodoCategoryServiceImpl()
    }
}
