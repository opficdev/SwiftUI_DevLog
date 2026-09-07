//
//  TodoWindowCoordinator.swift
//  Entry
//
//  Created by opfic on 5/31/26.
//

import Combine
import Foundation
import Domain
import PresentationShared

@MainActor
@Observable
final class TodoWindowCoordinator {
    @ObservationIgnored
    @Dependency(\.trackAnalyticsEventUseCase) private var trackAnalyticsEventUseCase
    @ObservationIgnored
    private var listStore: StoreOf<TodoListFeature>?
    @ObservationIgnored
    private var detailStore: StoreOf<TodoDetailFeature>?
    @ObservationIgnored
    private var cancellable: AnyCancellable?

    func bindWindowEvent(_ windowEvent: TodoEditorWindowEvent) {
        guard cancellable == nil else { return }

        cancellable = windowEvent.submits
            .sink { [weak self] submit in
                self?.handleTodoEditorSubmit(submit)
            }
    }

    func makeListStore(category: TodoCategory) -> StoreOf<TodoListFeature> {
        if let listStore,
           listStore.category == category {
            return listStore
        }

        let listStore = Store(initialState: TodoListFeature.State(category: category)) {
            TodoListFeature()
        }
        self.listStore = listStore
        return listStore
    }

    func makeDetailStore(
        todoId: String,
        showEditButton: Bool = true
    ) -> StoreOf<TodoDetailFeature> {
        if let detailStore,
           detailStore.todoId == todoId,
           detailStore.showEditButton == showEditButton {
            return detailStore
        }
        let detailStore = Store(
            initialState: TodoDetailFeature.State(
                todoId: todoId,
                showEditButton: showEditButton
            )
        ) {
            TodoDetailFeature()
        }
        self.detailStore = detailStore
        return detailStore
    }

    private func handleTodoEditorSubmit(_ submit: TodoEditorWindowSubmit) {
        switch submit {
        case .create(let value):
            trackAnalyticsEventUseCase.execute(.todoCreate)
            if let listStore,
               value.matchesCreate(category: listStore.category, source: .list) {
                listStore.send(.view(.refresh))
            }
        case .update(let value, let todo):
            if let detailStore,
               value.matchesEdit(todoId: detailStore.todoId) {
                detailStore.send(.setTodo(todo))
            }
        }
    }
}
