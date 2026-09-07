//
//  WidgetTodoSnapshotRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct WidgetTodoSnapshotRepositoryGraphInput {
    public let queryService: TodoQueryService

    public init(queryService: TodoQueryService) {
        self.queryService = queryService
    }
}

@DependencyGraph(input: WidgetTodoSnapshotRepositoryGraphInput.self)
public final class WidgetTodoSnapshotRepositoryGraph {
    @Provide
    private func makeWidgetTodoSnapshotRepository() -> WidgetTodoSnapshotRepository {
        WidgetTodoSnapshotRepositoryImpl(queryService: input.queryService)
    }
}
