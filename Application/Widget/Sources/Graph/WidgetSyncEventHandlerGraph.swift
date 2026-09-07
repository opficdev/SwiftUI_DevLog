//
//  WidgetSyncEventHandlerGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

public struct WidgetSyncEventHandlerGraphInput {
    public let eventBus: WidgetSyncEventBus
    public let repository: WidgetTodoSnapshotRepository
    public let snapshotUpdater: WidgetSnapshotUpdater

    public init(
        eventBus: WidgetSyncEventBus,
        repository: WidgetTodoSnapshotRepository,
        snapshotUpdater: WidgetSnapshotUpdater
    ) {
        self.eventBus = eventBus
        self.repository = repository
        self.snapshotUpdater = snapshotUpdater
    }
}

@DependencyGraph(input: WidgetSyncEventHandlerGraphInput.self)
public final class WidgetSyncEventHandlerGraph {
    @Provide(.lazy)
    private func makeWidgetSyncEventHandler() -> WidgetSyncEventHandler {
        WidgetSyncEventHandler(
            eventBus: input.eventBus,
            repository: input.repository,
            snapshotUpdater: input.snapshotUpdater
        )
    }
}
