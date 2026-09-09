//
//  HomeFeature+Effects.swift
//  HomeTab
//
//  Created by opfic on 6/14/26.
//

import Combine
import Core
import Domain
import Foundation
import PresentationShared

extension HomeFeature {
    private enum CancelID: Hashable {
        case delayedTodoEditor
        case networkConnectivity
    }

    func observeNetworkConnectivityEffect() -> Effect<Action> {
        .publisher { [networkConnectivityUseCase] in
            networkConnectivityUseCase.observe()
                .map { .store(.networkStatusChanged($0)) }
        }
        .cancellable(id: CancelID.networkConnectivity, cancelInFlight: true)
    }

    func fetchTodoCategoryPreferencesEffect() -> Effect<Action> {
        .run { [fetchPreferencesUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.preferences.target, mode: .immediate)))
            do {
                let preferences = try await fetchPreferencesUseCase.execute()
                await send(.store(.setTodoCategory(preferences.map(TodoCategoryItem.init(from:)))))
            } catch {
                await send(.store(.setAlert(isPresented: true)))
            }
            await send(.loading(.end(target: LoadingTarget.preferences.target, mode: .immediate)))
        }
    }

    func fetchRecentTodosEffect() -> Effect<Action> {
        .run { [fetchTodosUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.recentTodos.target, mode: .immediate)))
            do {
                let page = try await fetchRecentTodos(fetchTodosUseCase: fetchTodosUseCase)
                let items = page.items
                    .filter { $0.createdAt != $0.updatedAt }
                    .prefix(5)
                    .compactMap(RecentTodoItem.init(from:))
                await send(.store(.updateRecentTodos(Array(items))))
            } catch {
                await send(.store(.setAlert(isPresented: true)))
            }
            await send(.loading(.end(target: LoadingTarget.recentTodos.target, mode: .immediate)))
        }
    }

    func trackTodoCreateEffect() -> Effect<Action> {
        .run { [trackAnalyticsEventUseCase] _ in
            trackAnalyticsEventUseCase.execute(.todoCreate)
        }
    }

    func updateTodoCategoryPreferencesEffect(_ items: [TodoCategoryItem]) -> Effect<Action> {
        .run { [updatePreferencesUseCase] send in
            do {
                try await updatePreferencesUseCase.execute(items.map(\.preference))
            } catch {
                await send(.store(.setAlert(isPresented: true)))
            }
        }
    }

    func delayedTodoEditorEffect() -> Effect<Action> {
        .run { [clock] send in
            // iOS 17에서 시트 dismiss 직후 fullScreenCover를 바로 올리지 않도록 하기 위해서 0.1초 딜레이
            try await clock.sleep(for: .seconds(0.1))
            await send(.store(.setPresentation(.todoEditor, true)))
        }
        .cancellable(id: CancelID.delayedTodoEditor, cancelInFlight: true)
    }

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

    static func setPresentation(
        _ state: inout State,
        presentation: Presentation,
        isPresented: Bool
    ) {
        switch presentation {
        case .todoEditor:
            state.fullScreenCover = isPresented ? state.selectedTodoCategory.map(FullScreenCoverState.todoEditor) : nil
            if !isPresented {
                state.selectedTodoCategory = nil
            }
        case .contentPicker:
            state.sheet = isPresented ? .contentPicker : state.showContentPicker ? nil : state.sheet
        case .searchView:
            state.fullScreenCover = isPresented ? .search : nil
        }
    }

    static func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        guard isPresented else {
            state.alert = nil
            return
        }

        state.alert = alertState()
    }

    static func alertState() -> AlertState<Never> {
        return AlertState<Never> {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: "common_error_message", bundle: PresentationResources.bundle))
        }
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
