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
                await send(.store(.setAlert(isPresented: true, type: .error)))
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
                await send(.store(.setAlert(isPresented: true, type: .error)))
            }
            await send(.loading(.end(target: LoadingTarget.recentTodos.target, mode: .immediate)))
        }
    }

    func fetchWebPagesEffect() -> Effect<Action> {
        .run { [fetchWebPagesUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.webPage.target, mode: .immediate)))
            do {
                let pages = try await fetchWebPagesUseCase.execute("")
                await send(.store(.updateWebPages(pages.map(WebPageItem.init(from:)))))
            } catch {
                await send(.store(.setAlert(isPresented: true, type: .error)))
            }
            await send(.loading(.end(target: LoadingTarget.webPage.target, mode: .immediate)))
        }
    }

    func addWebPageEffect(_ urlString: String) -> Effect<Action> {
        .run { [addWebPageUseCase, fetchWebPagesUseCase, trackAnalyticsEventUseCase] send in
            await send(.loading(.begin(target: LoadingTarget.overlay.target, mode: .delayed)))
            do {
                try await addWebPageUseCase.execute(urlString)
                trackAnalyticsEventUseCase.execute(.webPageCreate)
                let pages = try await fetchWebPagesUseCase.execute("")
                await send(.store(.updateWebPages(pages.map(WebPageItem.init(from:)))))
                await send(.store(.setSheet(nil)))
            } catch {
                await send(.store(.setAlert(isPresented: true, type: .error)))
            }
            await send(.loading(.end(target: LoadingTarget.overlay.target, mode: .delayed)))
        }
    }

    func trackTodoCreateEffect() -> Effect<Action> {
        .run { [trackAnalyticsEventUseCase] _ in
            trackAnalyticsEventUseCase.execute(.todoCreate)
        }
    }

    func deleteWebPageEffect(_ page: WebPageItem) -> Effect<Action> {
        .run { [deleteWebPageUseCase] send in
            do {
                try await deleteWebPageUseCase.execute(
                    id: page.id,
                    urlString: page.url.absoluteString
                )
            } catch {
                await send(.store(.handleWebPageDeleteFailure(page.id)))
                await send(.store(.setAlert(isPresented: true, type: .error)))
            }
        }
    }

    func undoDeleteWebPageEffect(_ webPage: DeletedWebPage) -> Effect<Action> {
        .run { [undoDeleteWebPageUseCase, addWebPageUseCase] send in
            do {
                try await undoDeleteWebPageUseCase.execute(webPage.id)
                try await addWebPageUseCase.execute(webPage.urlString)
            } catch {
                await send(.store(.setWebPageHidden(webPage.id, true)))
                await send(.store(.setAlert(isPresented: true, type: .error)))
            }
        }
    }

    func updateTodoCategoryPreferencesEffect(_ items: [TodoCategoryItem]) -> Effect<Action> {
        .run { [updatePreferencesUseCase] send in
            do {
                try await updatePreferencesUseCase.execute(items.map(\.preference))
            } catch {
                await send(.store(.setAlert(isPresented: true, type: .error)))
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
            state.sheet = isPresented ? .contentPicker(.init()) : state.showContentPicker ? nil : state.sheet
        case .searchView:
            state.fullScreenCover = isPresented ? .search : nil
        }
    }

    static func setAlert(
        _ state: inout State,
        isPresented: Bool,
        type: AlertType?
    ) {
        guard isPresented, let type else {
            state.alert = nil
            return
        }

        state.alert = alertState(for: type)
    }

    static func alertState(for type: AlertType) -> AlertState<Never> {
        let title: String
        let message: String

        switch type {
        case .invalidURL:
            title = String(localized: "home_invalid_url_title", bundle: PresentationResources.bundle)
            message = String(localized: "home_invalid_url_message", bundle: PresentationResources.bundle)
        case .error:
            title = String(localized: "common_error_title", bundle: PresentationResources.bundle)
            message = String(localized: "common_error_message", bundle: PresentationResources.bundle)
        }

        return AlertState<Never> {
            TextState(title)
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(message)
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

    static func normalizedWebPageURL(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed == "https://" || trimmed == "http://" {
            return nil
        }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}
