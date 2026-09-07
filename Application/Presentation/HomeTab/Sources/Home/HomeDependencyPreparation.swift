//
//  HomeDependencyPreparation.swift
//  HomeTab
//
//  Created by opfic on 9/7/26.
//

import Domain
import PresentationShared

public enum HomeDependencyPreparation {
    public static func prepareTodoCategory(
        _ dependencies: inout DependencyValues,
        updateTodoCategoryPreferencesUseCase: UpdateTodoCategoryPreferencesUseCase,
        todoMutationEventBus: TodoMutationEventBus
    ) {
        dependencies.homeUpdateTodoCategoryPreferencesUseCase = updateTodoCategoryPreferencesUseCase
        dependencies.homeTodoMutationEventBus = todoMutationEventBus
    }

    public static func prepareWebPage(
        _ dependencies: inout DependencyValues,
        addWebPageUseCase: AddWebPageUseCase,
        deleteWebPageUseCase: DeleteWebPageUseCase,
        undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase,
        fetchWebPagesUseCase: FetchWebPagesUseCase
    ) {
        dependencies.homeAddWebPageUseCase = addWebPageUseCase
        dependencies.homeDeleteWebPageUseCase = deleteWebPageUseCase
        dependencies.homeUndoDeleteWebPageUseCase = undoDeleteWebPageUseCase
        dependencies.homeFetchWebPagesUseCase = fetchWebPagesUseCase
    }

    public static func prepareTodo(
        _ dependencies: inout DependencyValues,
        fetchTodosUseCase: FetchTodosUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    ) {
        dependencies.homeFetchTodosUseCase = fetchTodosUseCase
        dependencies.homeNetworkConnectivityUseCase = networkConnectivityUseCase
    }

    public static func prepareSearch(
        _ dependencies: inout DependencyValues,
        fetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        fetchWebPagesUseCase: FetchWebPagesUseCase,
        updateRecentSearchQueriesUseCase: UpdateRecentSearchQueriesUseCase
    ) {
        dependencies.homeFetchRecentSearchQueriesUseCase = fetchRecentSearchQueriesUseCase
        dependencies.searchFetchTodosUseCase = fetchTodosUseCase
        dependencies.searchFetchWebPagesUseCase = fetchWebPagesUseCase
        dependencies.searchUpdateRecentQueriesUseCase = updateRecentSearchQueriesUseCase
    }
}

extension DependencyValues {
    var homeTodoMutationEventBus: TodoMutationEventBus {
        get { self[HomeTodoMutationEventBusKey.self] }
        set { self[HomeTodoMutationEventBusKey.self] = newValue }
    }

    var homeFetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase {
        get { self[HomeFetchRecentSearchQueriesUseCaseKey.self] }
        set { self[HomeFetchRecentSearchQueriesUseCaseKey.self] = newValue }
    }
}

private enum HomeTodoMutationEventBusKey: DependencyKey {
    static var liveValue: TodoMutationEventBus {
        preconditionFailure("TodoMutationEventBus must be provided.")
    }
}

private enum HomeFetchRecentSearchQueriesUseCaseKey: DependencyKey {
    static var liveValue: FetchRecentSearchQueriesUseCase {
        preconditionFailure("FetchRecentSearchQueriesUseCase must be provided.")
    }
}
