//
//  TodayDependencyPreparation.swift
//  TodayTab
//
//  Created by opfic on 9/7/26.
//

import Domain
import PresentationShared

public enum TodayDependencyPreparation {
    public static func prepare(
        _ dependencies: inout DependencyValues,
        fetchTodosUseCase: FetchTodosUseCase,
        fetchCategoryPreferencesUseCase: FetchTodoCategoryPreferencesUseCase
    ) {
        dependencies.todayFetchTodosUseCase = fetchTodosUseCase
        dependencies.fetchTodoCategoryPreferencesUseCase = fetchCategoryPreferencesUseCase
    }
}
