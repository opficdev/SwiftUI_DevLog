//
//  PushNotificationListViewCoordinator.swift
//  NotificationTab
//
//  Created by opfic on 5/29/26.
//

import Foundation
import Domain
import PresentationShared

@MainActor
@Observable
public final class PushNotificationListViewCoordinator {
    let store: StoreOf<PushNotificationListFeature>
    @ObservationIgnored
    private var todoDetailStore: StoreOf<TodoDetailFeature>?
    @ObservationIgnored
    private var fetchNotificationsTask: Task<Void, Never>?

    public init() {
        @Dependency(\.fetchPushNotificationQueryUseCase) var fetchQueryUseCase

        self.store = Store(
            initialState: PushNotificationListFeature.State(
                query: fetchQueryUseCase.execute()
            )
        ) {
            PushNotificationListFeature()
        }
    }

    public var selectedTodoId: String? {
        store.selectedTodoId?.id
    }

    public func fetchData() {
        fetchNotificationsTask?.cancel()
        store.send(.view(.stopObserving))
        let query = store.query
        let task = store.send(.view(.fetchNotifications))
        fetchNotificationsTask = Task { [store] in
            await task.finish()
            guard !Task.isCancelled, store.query == query else { return }
            store.send(.view(.startObserving))
        }
    }

    public func makeTodoDetailStore(todoId: String) -> StoreOf<TodoDetailFeature> {
        if let todoDetailStore,
           todoDetailStore.todoId == todoId,
           !todoDetailStore.showEditButton {
            return todoDetailStore
        }

        let todoDetailStore = Store(
            initialState: TodoDetailFeature.State(
                todoId: todoId,
                showEditButton: false
            )
        ) {
            TodoDetailFeature()
        }
        self.todoDetailStore = todoDetailStore
        return todoDetailStore
    }
}
