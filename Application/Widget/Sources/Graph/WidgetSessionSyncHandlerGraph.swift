//
//  WidgetSessionSyncHandlerGraph.swift
//  Widget
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

public struct WidgetSessionSyncHandlerGraphInput {
    public let provider: AuthSessionStateProvider
    public let widgetSyncEventBus: WidgetSyncEventBus

    public init(
        provider: AuthSessionStateProvider,
        widgetSyncEventBus: WidgetSyncEventBus
    ) {
        self.provider = provider
        self.widgetSyncEventBus = widgetSyncEventBus
    }
}

@DependencyGraph(input: WidgetSessionSyncHandlerGraphInput.self)
public final class WidgetSessionSyncHandlerGraph {
    @Provide(.lazy)
    private func makeWidgetSessionSyncHandler() -> WidgetSessionSyncHandler {
        WidgetSessionSyncHandler(
            provider: input.provider,
            widgetSyncEventBus: input.widgetSyncEventBus
        )
    }
}
