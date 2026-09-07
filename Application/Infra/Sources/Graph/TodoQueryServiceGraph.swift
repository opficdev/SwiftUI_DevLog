//
//  TodoQueryServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class TodoQueryServiceGraph {
    public init() { }

    @Provide
    private func makeTodoQueryService() -> TodoQueryService {
        TodoQueryServiceImpl()
    }
}
