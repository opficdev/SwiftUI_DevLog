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
        updateTodoCategoryPreferencesUseCase: UpdateTodoCategoryPreferencesUseCase
    ) {
        dependencies.homeUpdateTodoCategoryPreferencesUseCase = updateTodoCategoryPreferencesUseCase
    }

    public static func prepareTodo(
        _ dependencies: inout DependencyValues,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    ) {
        dependencies.homeNetworkConnectivityUseCase = networkConnectivityUseCase
    }

    public static func prepareSearch(
        _ dependencies: inout DependencyValues,
        fetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        updateRecentSearchQueriesUseCase: UpdateRecentSearchQueriesUseCase
    ) {
        dependencies.homeFetchRecentSearchQueriesUseCase = fetchRecentSearchQueriesUseCase
        dependencies.searchFetchTodosUseCase = fetchTodosUseCase
        dependencies.searchUpdateRecentQueriesUseCase = updateRecentSearchQueriesUseCase
    }
}

extension DependencyValues {
    var homeFetchRecentSearchQueriesUseCase: FetchRecentSearchQueriesUseCase {
        get { self[HomeFetchRecentSearchQueriesUseCaseKey.self] }
        set { self[HomeFetchRecentSearchQueriesUseCaseKey.self] = newValue }
    }
}

private enum HomeFetchRecentSearchQueriesUseCaseKey: DependencyKey {
    static var liveValue: FetchRecentSearchQueriesUseCase {
        preconditionFailure("FetchRecentSearchQueriesUseCase must be provided.")
    }
}
