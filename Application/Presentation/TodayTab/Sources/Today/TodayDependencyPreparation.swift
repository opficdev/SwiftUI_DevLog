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
        fetchDisplayOptionsUseCase: FetchTodayDisplayOptionsUseCase,
        fetchTodosUseCase: FetchTodosUseCase,
        updateDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase
    ) {
        dependencies.todayFetchDisplayOptionsUseCase = fetchDisplayOptionsUseCase
        dependencies.todayFetchTodosUseCase = fetchTodosUseCase
        dependencies.updateTodayDisplayOptionsUseCase = updateDisplayOptionsUseCase
    }
}

extension DependencyValues {
    var todayFetchDisplayOptionsUseCase: FetchTodayDisplayOptionsUseCase {
        get { self[TodayFetchDisplayOptionsUseCaseKey.self] }
        set { self[TodayFetchDisplayOptionsUseCaseKey.self] = newValue }
    }
}

private enum TodayFetchDisplayOptionsUseCaseKey: DependencyKey {
    static var liveValue: FetchTodayDisplayOptionsUseCase {
        preconditionFailure("FetchTodayDisplayOptionsUseCase must be provided.")
    }
}
