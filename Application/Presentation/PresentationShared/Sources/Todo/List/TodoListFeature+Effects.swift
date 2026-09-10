//
//  TodoListFeature+Effects.swift
//  PresentationShared
//
//  Created by opfic on 6/12/26.
//

import ComposableArchitecture
import Core
import Domain
import Foundation

extension TodoListFeature {
    func searchEffect(
        _ keyword: String,
        category: TodoCategory
    ) -> Effect<Action> {
        .run { [fetchTodosUseCase] send in
            do {
                let query = TodoQuery(categoryId: category.storageValue, keyword: keyword)
                let page = try await fetchTodosUseCase.execute(query, cursor: nil)
                try Task.checkCancellation()
                await send(.store(.fetchSearchResults(page.items.compactMap(TodoListItem.init(from:)))))
                await send(.loading(.end(target: .default, mode: .immediate)))
            } catch is CancellationError {
                return
            } catch {
                await send(.store(.setAlert(true)))
                await send(.loading(.end(target: .default, mode: .immediate)))
            }
        }
        .cancellable(id: CancelID.request, cancelInFlight: true)
    }

    func toggleCompletedEffect(_ item: TodoListItem) -> Effect<Action> {
        .concatenate(
            .send(.loading(.begin(target: .default, mode: .delayed))),
            .run { [fetchTodoByIdUseCase, upsertTodoUseCase, trackAnalyticsEventUseCase] send in
                do {
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    let now = Date()
                    todo.isCompleted.toggle()
                    todo.completedAt = todo.isCompleted ? now : nil
                    todo.updatedAt = now
                    try await upsertTodoUseCase.execute(todo)
                    if todo.isCompleted {
                        trackAnalyticsEventUseCase.execute(.todoComplete)
                    }
                    guard let todoListItem = TodoListItem(from: todo) else {
                        await send(.store(.setAlert(true)))
                        await send(.loading(.end(target: .default, mode: .delayed)))
                        return
                    }
                    await send(.store(.didToggleCompleted(todoListItem)))
                    await send(.loading(.end(target: .default, mode: .delayed)))
                } catch {
                    await send(.store(.setAlert(true)))
                    await send(.loading(.end(target: .default, mode: .delayed)))
                }
            }
        )
    }

    func trackTodoCreateEffect() -> Effect<Action> {
        .run { [trackAnalyticsEventUseCase] _ in
            trackAnalyticsEventUseCase.execute(.todoCreate)
        }
    }

    func togglePinnedEffect(_ item: TodoListItem) -> Effect<Action> {
        .concatenate(
            .send(.loading(.begin(target: .default, mode: .delayed))),
            .run { [fetchTodoByIdUseCase, upsertTodoUseCase] send in
                do {
                    var todo = try await fetchTodoByIdUseCase.execute(item.id)
                    todo.isPinned.toggle()
                    todo.updatedAt = Date()
                    try await upsertTodoUseCase.execute(todo)
                    guard let todoListItem = TodoListItem(from: todo) else {
                        await send(.store(.setAlert(true)))
                        await send(.loading(.end(target: .default, mode: .delayed)))
                        return
                    }
                    await send(.store(.didTogglePinned(todoListItem)))
                    await send(.loading(.end(target: .default, mode: .delayed)))
                } catch {
                    await send(.store(.setAlert(true)))
                    await send(.loading(.end(target: .default, mode: .delayed)))
                }
            }
        )
    }

    func swipeTodoEffect(_ todo: TodoListItem, state: inout State) -> Effect<Action> {
        guard state.todos.contains(where: { $0.id == todo.id }) else { return .none }
        state.undoTodoId = todo.id
        Self.setTodoHidden(&state, todoId: todo.id, isHidden: true)
        return deleteEffect(todo)
    }

    func deleteEffect(_ item: TodoListItem) -> Effect<Action> {
        .run { [deleteTodoUseCase] send in
            do {
                try await deleteTodoUseCase.execute(item.id)
            } catch {
                await send(.store(.setTodoHidden(item.id, false)))
                await send(.store(.setAlert(true)))
            }
        }
    }

    func undoDeleteEffect(_ todoId: String) -> Effect<Action> {
        .run { [undoDeleteTodoUseCase] send in
            do {
                try await undoDeleteTodoUseCase.execute(todoId)
            } catch {
                await send(.store(.setTodoHidden(todoId, true)))
                await send(.store(.setAlert(true)))
            }
        }
    }

    static func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alert = isPresented ? Self.alertState() : nil
    }

    static func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: "common_error_message", bundle: PresentationResources.bundle))
        }
    }

    static func setTodoHidden(
        _ state: inout State,
        todoId: String,
        isHidden: Bool
    ) {
        if let todoIndex = state.todos.firstIndex(where: { $0.id == todoId }) {
            state.todos[todoIndex].isHidden = isHidden
        }

        if let searchResultIndex = state.searchResults.firstIndex(where: { $0.id == todoId }) {
            state.searchResults[searchResultIndex].isHidden = isHidden
        }
    }
}
