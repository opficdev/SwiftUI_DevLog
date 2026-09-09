//
//  HomeFeatureTestSupport.swift
//  HomeTabTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Combine
import Core
import Domain
import PresentationShared
@testable import HomeTab
import Foundation

@MainActor
struct HomeStoreTestAdapter {
    private let store: TestStoreOf<HomeFeature>
    private let clock: TestClock<Duration>

    var preferences: [TodoCategoryItem] { store.state.preferences }
    var recentTodos: [RecentTodoItem] { store.state.recentTodos }
    var isNetworkConnected: Bool { store.state.isNetworkConnected }
    var showContentPicker: Bool { store.state.showContentPicker }
    var showCategoryManage: Bool {
        store.state.sheet?.categoryManageState != nil
    }
    var showTodoEditor: Bool { store.state.showTodoEditor }

    init(
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase = FetchTodoCategoryPreferencesUseCaseSpy(),
        updatePreferencesUseCase: UpdateTodoCategoryPreferencesUseCase = UpdateTodoCategoryPreferencesUseCaseSpy(),
        fetchTodosUseCase: FetchTodosUseCase = FetchTodosUseCaseSpy(),
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase = ObserveNetworkConnectivityUseCaseSpy(),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = HomeTrackAnalyticsEventUseCaseSpy(),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        let clock = TestClock()
        self.clock = clock
        store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.fetchTodoCategoryPreferencesUseCase = fetchPreferencesUseCase
            $0.homeUpdateTodoCategoryPreferencesUseCase = updatePreferencesUseCase
            $0.homeFetchTodosUseCase = fetchTodosUseCase
            $0.homeNetworkConnectivityUseCase = networkConnectivityUseCase
            $0.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
            $0.continuousClock = clock
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func startObserving() async {
        await store.send(.view(.startObserving))
        await drainReceivedActions()
    }

    func fetchData() async {
        await store.send(.view(.fetchData))
        await drainReceivedActions()
    }

    func setPresentation(_ presentation: HomeFeature.Presentation, _ isPresented: Bool) async {
        await store.send(.store(.setPresentation(presentation, isPresented)))
    }

    func tapTodoCategory(_ category: TodoCategory) async {
        await store.send(.view(.tapTodoCategory(category)))
        await clock.advance(by: .seconds(1))
        await settle()
    }

    func todoEditorCreated() async {
        await store.send(.view(.todoEditorCreated))
        await drainReceivedActions()
    }

    func tapManageTodoCategory() async {
        await store.send(.view(.tapManageTodoCategory))
        await drainReceivedActions()
    }

    func orderTodoCategory(_ items: [TodoCategoryItem]) async {
        await store.send(.sheet(.presented(.categoryManage(.delegate(.done(items))))))
        await drainReceivedActions()
    }

    func drainReceivedActions() async {
        for _ in 0..<12 {
            await store.skipReceivedActions(strict: false)
        }
    }

    func settle() async {
        await Task.yield()
        await drainReceivedActions()
    }
}

final class HomeTrackAnalyticsEventUseCaseSpy: TrackAnalyticsEventUseCase {
    private(set) var events = [AnalyticsEvent]()
    var hasTrackedTodoCreate: Bool {
        events.contains {
            guard case .todoCreate = $0 else { return false }
            return true
        }
    }

    func execute(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

func makeHomeTodo(
    id: String,
    category: TodoCategory = .system(.feature),
    number: Int = 1,
    title: String = "Todo",
    isPinned: Bool = false,
    tags: [String] = [],
    createdAt: Date = Date(timeIntervalSince1970: 0),
    updatedAt: Date = Date(timeIntervalSince1970: 10)
) -> Todo {
    Todo(
        id: id,
        isPinned: isPinned,
        isCompleted: false,
        isChecked: false,
        number: number,
        title: title,
        content: "content",
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: tags,
        category: category
    )
}
