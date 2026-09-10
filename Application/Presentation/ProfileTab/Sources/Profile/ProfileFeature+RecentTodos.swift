//
//  ProfileFeature+RecentTodos.swift
//  ProfileTab
//
//  Created by opfic on 9/10/26.
//

import Combine
import Core
import Domain
import Foundation
import PresentationShared

private enum RecentTodoCancelID: Hashable {
    case todoMutation
}

extension ProfileFeature {
    func observeTodoMutationEffect() -> Effect<Action> {
        .publisher { [todoMutationEventBus] in
            todoMutationEventBus.observe()
                .receive(on: DispatchQueue.main)
                .map { _ in .refreshRecentTodos }
        }
        .cancellable(id: RecentTodoCancelID.todoMutation, cancelInFlight: true)
    }

    func fetchRecentTodosEffect() -> Effect<Action> {
        .run { [fetchPreferencesUseCase, fetchTodosUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.recentTodos.target, mode: .immediate)))
            async let preferences = try? fetchPreferencesUseCase.execute()
            do {
                let page = try await fetchRecentTodos(fetchTodosUseCase: fetchTodosUseCase)
                let items = page.items
                    .filter { $0.createdAt != $0.updatedAt }
                    .prefix(5)
                    .compactMap(RecentTodoItem.init(from:))
                let recentTodos = Array(items)
                if let categoryPreferences = await preferences {
                    let categories = categoryPreferences.map(TodoCategoryItem.init(from:))
                    await send(
                        .store(
                            .updateRecentTodos(
                                Self.syncRecentTodos(recentTodos, preferences: categories)
                            )
                        )
                    )
                } else {
                    await send(.store(.updateRecentTodos(recentTodos)))
                    await send(.setAlert(true))
                }
            } catch {
                await send(.setAlert(true))
            }
            await send(.loading(.end(target: LoadingTarget.recentTodos.target, mode: .immediate)))
        }
    }
}

private extension ProfileFeature {
    func fetchRecentTodos(fetchTodosUseCase: FetchTodosUseCase) async throws -> TodoPage {
        try await fetchTodosUseCase.execute(
            TodoQuery(
                sortTarget: .updatedAt,
                sortOrder: .latest,
                pageSize: 100
            ),
            cursor: nil
        )
    }

    static func syncRecentTodos(
        _ recentTodos: [RecentTodoItem],
        preferences: [TodoCategoryItem]
    ) -> [RecentTodoItem] {
        recentTodos.map { recentTodo in
            guard let item = preferences.first(where: {
                $0.category.storageValue == recentTodo.category.storageValue
            }) else {
                return recentTodo
            }

            var recentTodo = recentTodo
            recentTodo.category = item.category
            return recentTodo
        }
    }
}
