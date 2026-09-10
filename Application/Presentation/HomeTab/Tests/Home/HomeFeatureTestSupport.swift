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
    var webPages: [WebPageItem] { store.state.webPages }
    var isNetworkConnected: Bool { store.state.isNetworkConnected }
    var showContentPicker: Bool { store.state.showContentPicker }
    var showCategoryManage: Bool {
        store.state.sheet?.categoryManageState != nil
    }
    var showWebPageInputNavigation: Bool {
        store.state.sheet?.contentPickerState?.webPageInput != nil
    }
    var showTodoEditor: Bool { store.state.showTodoEditor }
    var showAlert: Bool { store.state.alert != nil }
    var alertType: HomeFeature.AlertType? {
        guard let title = store.state.alert?.title else { return nil }
        if title == TextState(String(localized: "home_invalid_url_title", bundle: PresentationResources.bundle)) {
            return .invalidURL
        }
        if title == TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle)) {
            return .error
        }
        return nil
    }
    var alertTitle: String {
        if let title = store.state.alert?.title {
            return String(state: title)
        }
        return ""
    }
    var webPageURLInput: String { store.state.webPageURLInput }

    init(
        fetchPreferencesUseCase: FetchTodoCategoryPreferencesUseCase = FetchTodoCategoryPreferencesUseCaseSpy(),
        updatePreferencesUseCase: UpdateTodoCategoryPreferencesUseCase = UpdateTodoCategoryPreferencesUseCaseSpy(),
        addWebPageUseCase: AddWebPageUseCase = AddWebPageUseCaseSpy(),
        deleteWebPageUseCase: DeleteWebPageUseCase = DeleteWebPageUseCaseSpy(),
        undoDeleteWebPageUseCase: UndoDeleteWebPageUseCase = UndoDeleteWebPageUseCaseSpy(),
        fetchTodosUseCase: FetchTodosUseCase = FetchTodosUseCaseSpy(),
        fetchWebPagesUseCase: FetchWebPagesUseCase = FetchWebPagesUseCaseSpy(webPages: []),
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
            $0.homeAddWebPageUseCase = addWebPageUseCase
            $0.homeDeleteWebPageUseCase = deleteWebPageUseCase
            $0.homeUndoDeleteWebPageUseCase = undoDeleteWebPageUseCase
            $0.homeFetchTodosUseCase = fetchTodosUseCase
            $0.homeFetchWebPagesUseCase = fetchWebPagesUseCase
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

    func openWebPageInput() async {
        await store.send(.sheet(.presented(.contentPicker(.tapWebPageInput))))
        await drainReceivedActions()
    }

    func setPresentation(_ presentation: HomeFeature.Presentation, _ isPresented: Bool) async {
        await store.send(.store(.setPresentation(presentation, isPresented)))
    }

    func setAlert(isPresented: Bool, type: HomeFeature.AlertType?) async {
        await store.send(.store(.setAlert(isPresented: isPresented, type: type)))
        await drainReceivedActions()
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

    func updateWebPageURLInput(_ input: String) async {
        await store.send(.binding(.set(\.webPageURLInput, input)))
    }

    func addWebPage() async {
        await store.send(.view(.addWebPage))
        await drainReceivedActions()
    }

    func deleteWebPage(_ page: WebPageItem) async {
        await store.send(.view(.deleteWebPage(page)))
        await drainReceivedActions()
    }

    func undoDeleteWebPage() async {
        await store.send(.view(.undoDeleteWebPage))
        await drainReceivedActions()
    }

    func finishDeleteWebPageToast(_ urlString: String) async {
        await store.send(.view(.finishDeleteWebPageToast(urlString)))
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

func makeHomeWebPage(
    id: String = "web-page-id",
    title: String = "OpenAI",
    urlString: String = "https://openai.com"
) -> WebPage {
    let url = URL(string: urlString)!
    return WebPage(
        id: id,
        title: title,
        url: url,
        displayURL: url,
        imageURL: nil
    )
}
