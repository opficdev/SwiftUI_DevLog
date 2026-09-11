//
//  TodayFeatureTestDoubles.swift
//  TodayTabTests
//
//  Created by opfic on 6/14/26.
//

import Foundation
import PresentationShared
import Core
import Domain
@testable import TodayTab

enum TodayTestError: Error {
    case failure
}

enum TodayTestSectionScope: Hashable, CaseIterable {
    case all
    case focused
    case overdue
    case dueSoon
}

enum TodayTestSectionCategory: Hashable {
    case later
    case unscheduled
    case focused
    case overdue
    case dueSoon
}

struct TodayDisplayedSection: Equatable {
    let category: TodayTestSectionCategory
    let itemIds: [String]
}

@MainActor
protocol TodayStateDriving {
    var todos: [TodayTodoItem] { get }
    var completedTodayTodos: [TodayTodoItem] { get }
    var todayTodos: [TodayTodoItem] { get }
    var todayAchievement: TodayFeature.TodayAchievement? { get }
    var todayInterval: DateInterval { get }
    var isTodayDataLoaded: Bool { get }
    var selectedSectionScope: TodayTestSectionScope { get }
    var displayOptions: TodayDisplayOptions { get }
    var showAlert: Bool { get }
    var isLoading: Bool { get }
    var displayedSections: [TodayDisplayedSection] { get }
    var summaryCounts: [TodayTestSectionScope: Int] { get }

    func fetchData() async
    func checkCurrentDate(_ date: Date) async
    func setSectionScope(_ scope: TodayTestSectionScope) async
    func setDueDateVisibility(_ visibility: TodayDisplayOptions.DueDateVisibility) async
    func setFocusVisibility(_ visibility: TodayDisplayOptions.FocusVisibility) async
    func resetDisplayOptions() async
    func completeTodo(_ item: TodayTodoItem) async
    func togglePinned(_ item: TodayTodoItem) async
}

@MainActor
struct TodayStoreTestAdapter: TodayStateDriving {
    private let store: TestStoreOf<TodayFeature>

    var todos: [TodayTodoItem] { store.state.todos }
    var completedTodayTodos: [TodayTodoItem] { store.state.completedTodayTodos }
    var todayTodos: [TodayTodoItem] { store.state.todayTodos }
    var todayAchievement: TodayFeature.TodayAchievement? { store.state.todayAchievement }
    var todayInterval: DateInterval { store.state.todayInterval }
    var isTodayDataLoaded: Bool { store.state.isTodayDataLoaded }
    var selectedSectionScope: TodayTestSectionScope { store.state.selectedSectionScope.testValue }
    var displayOptions: TodayDisplayOptions { store.state.displayOptions }
    var showAlert: Bool { store.state.alert != nil }
    var isLoading: Bool { store.state.isLoading }
    var displayedSections: [TodayDisplayedSection] { store.state.sections.map(\.testValue) }
    var summaryCounts: [TodayTestSectionScope: Int] {
        Dictionary(
            uniqueKeysWithValues: store.state.summaryCounts.map { key, value in
                (key.testValue, value)
            }
        )
    }

    init(
        fetchUseCase: FetchTodosUseCase = TodayFetchTodosUseCaseSpy(),
        fetchTodoByIdUseCase: FetchTodoByIdUseCase = TodayFetchTodoByIdUseCaseSpy(),
        upsertUseCase: UpsertTodoUseCase = TodayUpsertTodoUseCaseSpy(),
        fetchDisplayOptionsUseCase: FetchTodayDisplayOptionsUseCase = TodayFetchDisplayOptionsUseCaseSpy(),
        updateDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase = TodayUpdateDisplayOptionsUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = TodayTrackAnalyticsEventUseCaseSpy(),
        now: Date = Date(),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        store = TestStore(
            initialState: TodayFeature.State(
                displayOptions: fetchDisplayOptionsUseCase.execute(),
                now: now
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.todayFetchTodosUseCase = fetchUseCase
            $0.fetchTodoByIdUseCase = fetchTodoByIdUseCase
            $0.upsertTodoUseCase = upsertUseCase
            $0.updateTodayDisplayOptionsUseCase = updateDisplayOptionsUseCase
            $0.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
            $0.date.now = now
            $0.continuousClock = ContinuousClock()
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func fetchData() async {
        await store.send(.fetchData)
        await drainReceivedActions()
    }

    func checkCurrentDate(_ date: Date) async {
        await store.send(.checkCurrentDate(date))
        await drainReceivedActions()
    }

    func receiveCompletedTodayTodos(
        _ todos: [TodayTodoItem],
        interval: DateInterval
    ) async {
        await store.send(.store(.setCompletedTodayTodos(todos, interval: interval)))
    }

    func receiveTodos(
        incomplete: [TodayTodoItem],
        completedToday: [TodayTodoItem],
        interval: DateInterval
    ) async {
        await store.send(.store(.setTodos(
            incomplete: incomplete,
            completedToday: completedToday,
            interval: interval
        )))
    }

    func receiveUpdatedTodo(_ item: TodayTodoItem) async {
        await store.send(.store(.updateTodo(item)))
    }

    func setSectionScope(_ scope: TodayTestSectionScope) async {
        await store.send(.setSectionScope(scope.featureValue))
    }

    func setDueDateVisibility(_ visibility: TodayDisplayOptions.DueDateVisibility) async {
        await store.send(.binding(.set(\.displayOptions.dueDateVisibility, visibility)))
        await drainReceivedActions()
    }

    func setFocusVisibility(_ visibility: TodayDisplayOptions.FocusVisibility) async {
        await store.send(.binding(.set(\.displayOptions.focusVisibility, visibility)))
        await drainReceivedActions()
    }

    func resetDisplayOptions() async {
        await store.send(.resetDisplayOptions)
        await drainReceivedActions()
    }

    func completeTodo(_ item: TodayTodoItem) async {
        await store.send(.completeTodo(item))
        await drainReceivedActions()
    }

    func togglePinned(_ item: TodayTodoItem) async {
        await store.send(.togglePinned(item))
        await drainReceivedActions()
    }

    private func drainReceivedActions() async {
        for _ in 0..<10 {
            await store.skipReceivedActions(strict: false)
        }
    }
}

private extension TodayTestSectionScope {
    var featureValue: TodayFeature.SectionScope {
        switch self {
        case .all:
            return .all
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayFeature.SectionScope {
    var testValue: TodayTestSectionScope {
        switch self {
        case .all:
            return .all
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayFeature.SectionCategory {
    var testValue: TodayTestSectionCategory {
        switch self {
        case .later:
            return .later
        case .unscheduled:
            return .unscheduled
        case .focused:
            return .focused
        case .overdue:
            return .overdue
        case .dueSoon:
            return .dueSoon
        }
    }
}

private extension TodayFeature.SectionContent {
    var testValue: TodayDisplayedSection {
        TodayDisplayedSection(
            category: category.testValue,
            itemIds: items.map(\.id)
        )
    }
}
