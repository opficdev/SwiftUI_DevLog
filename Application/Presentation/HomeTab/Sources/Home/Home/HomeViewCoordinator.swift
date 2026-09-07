//
//  HomeViewCoordinator.swift
//  HomeTab
//
//  Created by opfic on 5/10/26.
//

import Combine
import Foundation
import Domain
import PresentationShared

@MainActor
@Observable
public final class HomeViewCoordinator {
    let store: StoreOf<HomeFeature>
    public let router = NavigationRouter<HomeRoute>()
    @ObservationIgnored
    @Dependency(\.homeTodoMutationEventBus) private var todoMutationEventBus
    @ObservationIgnored
    @Dependency(\.homeFetchRecentSearchQueriesUseCase) private var fetchRecentSearchQueriesUseCase
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private var isTodoMutationEventBound = false
    @ObservationIgnored
    private var isWindowEventBound = false

    public init() {
        self.store = Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
        self.store.send(.view(.startObserving))
    }

    public func fetchData() {
        store.send(.view(.fetchData))
    }

    public func refreshRecentTodos() {
        store.send(.view(.refreshRecentTodos))
    }

    public func bindTodoMutationEvent() {
        guard isTodoMutationEventBound == false else { return }
        isTodoMutationEventBound = true

        todoMutationEventBus.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .updated, .deleted, .restored:
                    self.refreshRecentTodos()
                }
            }
            .store(in: &cancellables)
    }

    public func bindWindowEvent(_ windowEvent: TodoEditorWindowEvent) {
        guard isWindowEventBound == false else { return }
        isWindowEventBound = true

        windowEvent.submits
            .receive(on: DispatchQueue.main)
            .sink { [weak self] submit in
                guard case .create(let value) = submit,
                      value.matchesCreate(source: .home) else { return }
                self?.store.send(.view(.todoEditorCreated))
            }
            .store(in: &cancellables)
    }

    func makeSearchStore() -> StoreOf<SearchFeature> {
        Store(
            initialState: SearchFeature.State(
                recentQueries: fetchRecentSearchQueriesUseCase.execute()
            )
        ) {
            SearchFeature()
        }
    }
}
