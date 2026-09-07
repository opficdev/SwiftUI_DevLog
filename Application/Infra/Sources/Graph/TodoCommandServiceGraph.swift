//
//  TodoCommandServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class TodoCommandServiceGraph {
    public init() { }

    @Provide
    private func makeTodoCommandService() -> TodoCommandService {
        TodoCommandServiceImpl()
    }
}
