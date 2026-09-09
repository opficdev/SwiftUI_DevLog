//
//  SearchFeatureTestDoubles.swift
//  HomeTabTests
//
//  Created by opfic on 6/12/26.
//

import Foundation
import Core
import Domain
import PresentationShared
@testable import HomeTab

@MainActor
struct SearchStoreTestAdapter {
    private let store: TestStoreOf<SearchFeature>

    var searchQuery: String { store.state.searchQuery }
    var isSearching: Bool { store.state.isSearching }
    var isLoading: Bool { store.state.isLoading }
    var todos: [TodoListItem] { store.state.todos }
    var recentQueries: [String] { Array(store.state.recentQueries) }
    var showAllTodos: Bool { store.state.showAllTodos }
    var isHashOnlyQuery: Bool { store.state.isHashOnlyQuery }
    var alert: AlertState<Never>? { store.state.alert }

    init(
        recentQueries: [String] = [],
        initialTodos: [TodoListItem] = [],
        isSearching: Bool = false,
        isLoading: Bool = false,
        fetchTodosUseCase: FetchTodosUseCase = SearchFetchTodosUseCaseSpy(),
        updateRecentQueriesUseCase: UpdateRecentSearchQueriesUseCase = SearchUpdateRecentQueriesUseCaseSpy(),
        configureDependencies: ((inout DependencyValues) -> Void)? = nil
    ) {
        var state = SearchFeature.State(recentQueries: recentQueries)
        state.todos = initialTodos
        state.isSearching = isSearching
        if isLoading {
            state.loading.setImmediateLoading()
        }
        store = TestStore(initialState: state) {
            SearchFeature()
        } withDependencies: {
            $0.searchFetchTodosUseCase = fetchTodosUseCase
            $0.searchUpdateRecentQueriesUseCase = updateRecentQueriesUseCase
            $0.continuousClock = ContinuousClock()
            configureDependencies?(&$0)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func addRecentQuery(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxRecentQueries = 20
        await store.send(.addRecentQuery(query)) {
            guard !trimmed.isEmpty else { return }
            $0.recentQueries.remove(trimmed)
            $0.recentQueries.insert(trimmed, at: 0)
            if maxRecentQueries < $0.recentQueries.count {
                $0.recentQueries = OrderedSet($0.recentQueries.prefix(maxRecentQueries))
            }
        }
    }

    func removeRecentQuery(_ query: String) async {
        await store.send(.removeRecentQuery(query)) {
            $0.recentQueries.remove(query)
        }
    }

    func clearRecentQueries() async {
        await store.send(.clearRecentQueries) {
            $0.recentQueries = []
        }
    }

    func onAppear() async {
        await store.send(.onAppear)
        await store.receive(.binding(.set(\.isSearching, true))) {
            $0.isSearching = true
        }
    }

    func setShowAllTodos(_ value: Bool) async {
        await store.send(.setShowAllTodos(value)) {
            $0.showAllTodos = value
        }
    }

    func setSearchQuery(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let wasLoading = store.state.isLoading
        await store.send(.binding(.set(\.searchQuery, query))) {
            $0.searchQuery = query
            $0.showAllTodos = false
            if trimmed.isEmpty || $0.isHashOnlyQuery {
                $0.todos = []
            }
        }
        if wasLoading {
            await receiveEndLoading()
        }
        if !trimmed.isEmpty && !store.state.isHashOnlyQuery {
            await receiveBeginLoading()
        }
    }

    func applySearchQuery(_ query: String) async {
        await store.send(.store(.applySearchQuery(query)))
    }

    func setSearching(_ value: Bool) async {
        let wasLoading = store.state.isLoading
        await store.send(.binding(.set(\.isSearching, value))) {
            $0.isSearching = value
        }
        if !value, wasLoading {
            await receiveEndLoading()
        }
    }

    func receiveAppliedSearchQuery(_ query: String) async {
        await store.receive(.store(.applySearchQuery(query)))
    }

    func receiveSearchResults(todos: [TodoListItem]) async {
        let wasLoading = store.state.isLoading
        await store.receive(.store(.fetchTodos(todos))) {
            $0.todos = todos
        }
        if wasLoading {
            await receiveEndLoading()
        }
    }

    func receiveSearchFailure() async {
        let wasLoading = store.state.isLoading
        if wasLoading {
            await receiveEndLoading()
        }
        await store.receive(.store(.setAlert(true))) {
            $0.alert = expectedSearchErrorAlert()
        }
    }

    private func receiveBeginLoading() async {
        await store.receive(.loading(.begin(target: .default, mode: .immediate))) {
            $0.loading.setImmediateLoading()
        }
    }

    private func receiveEndLoading() async {
        await store.receive(.loading(.end(target: .default, mode: .immediate))) {
            $0.loading.setImmediateLoadingFinished()
        }
    }
}

private extension LoadingFeature.State {
    mutating func setImmediateLoading() {
        let target = LoadingFeature.Target.default
        immediateCountByTarget[target] = 1
        visibleTargets.insert(target)
        isLoading = !visibleTargets.isEmpty
    }

    mutating func setImmediateLoadingFinished() {
        let target = LoadingFeature.Target.default
        immediateCountByTarget[target] = 0
        visibleTargets.remove(target)
        isLoading = !visibleTargets.isEmpty
    }
}

final class SearchFetchTodosUseCaseSpy: FetchTodosUseCase {
    var page: TodoPage
    var error: Error?
    private(set) var queries = [TodoQuery]()

    init(page: TodoPage = TodoPage(items: [], nextCursor: nil)) {
        self.page = page
    }

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        queries.append(query)

        if let error {
            throw error
        }

        return page
    }
}

final class SearchUpdateRecentQueriesUseCaseSpy: UpdateRecentSearchQueriesUseCase {
    private(set) var queries = [[String]]()

    func execute(_ queries: [String]) {
        self.queries.append(queries)
    }
}

enum SearchFeatureTestError: Error {
    case failure
}

func makeSearchTodo(
    id: String = "todo-id",
    title: String = "Todo"
) -> Todo {
    Todo(
        id: id,
        isPinned: false,
        isCompleted: false,
        isChecked: false,
        number: 1,
        title: title,
        content: "content",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0),
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: .system(.feature)
    )
}

func expectedSearchErrorAlert() -> AlertState<Never> {
    AlertState {
        TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
    } actions: {
        ButtonState(role: .cancel) {
            TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
        }
    } message: {
        TextState(String(localized: "common_error_message", bundle: PresentationResources.bundle))
    }
}
