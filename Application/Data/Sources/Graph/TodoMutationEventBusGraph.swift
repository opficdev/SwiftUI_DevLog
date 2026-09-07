//
//  TodoMutationEventBusGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

@DependencyGraph
public final class TodoMutationEventBusGraph {
    public init() { }

    @Provide
    private func makeTodoMutationEventBus() -> TodoMutationEventBus {
        TodoMutationEventBusImpl()
    }
}
