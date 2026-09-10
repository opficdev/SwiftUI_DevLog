//
//  TodayFeature.swift
//  TodayTab
//
//  Created by opfic on 6/14/26.
//

import Core
import Domain
import Foundation
import PresentationShared

@Reducer
struct TodayFeature {
    enum SectionScope: Hashable, CaseIterable {
        case all
        case focused
        case overdue
        case dueSoon
    }

    enum SectionCategory: Hashable {
        case later
        case unscheduled
        case focused
        case overdue
        case dueSoon
    }

    struct SectionContent: Identifiable, Equatable {
        var id: SectionCategory { category }
        let category: SectionCategory
        let title: String
        let items: [TodayTodoItem]
    }

    struct SectionCollection {
        var focused: [TodayTodoItem] = []
        var overdue: [TodayTodoItem] = []
        var dueSoon: [TodayTodoItem] = []
        var later: [TodayTodoItem] = []
        var unscheduled: [TodayTodoItem] = []
    }

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        var todos: [TodayTodoItem] = []
        var selectedSectionScope: SectionScope = .all
        var displayOptions: TodayDisplayOptions
        var loading = LoadingFeature.State()

        init(displayOptions: TodayDisplayOptions = .default) {
            self.displayOptions = displayOptions
        }

        var isLoading: Bool {
            loading.isLoading
        }

        var sections: [SectionContent] {
            let now = Date()
            let items = TodayFeature.groupedSectionItems(
                from: TodayFeature.displayedTodos(
                    todos: todos,
                    displayOptions: displayOptions
                ),
                now: now
            )

            switch selectedSectionScope {
            case .all:
                return
                    TodayFeature.makeSection(
                        category: .focused,
                        title: String(localized: "today_section_focused", bundle: PresentationResources.bundle),
                        items: items.focused
                    )
                    + TodayFeature.makeSection(
                        category: .overdue,
                        title: String(localized: "today_section_overdue", bundle: PresentationResources.bundle),
                        items: items.overdue
                    )
                    + TodayFeature.makeSection(
                        category: .dueSoon,
                        title: String.localizedStringWithFormat(
                            String(localized: "today_section_due_soon_format", bundle: PresentationResources.bundle),
                            Int64(TodayFeature.upcomingWindowDays)
                        ),
                        items: items.dueSoon
                    )
                    + TodayFeature.makeSection(
                        category: .later,
                        title: String(localized: "today_section_later", bundle: PresentationResources.bundle),
                        items: items.later
                    )
                    + TodayFeature.makeSection(
                        category: .unscheduled,
                        title: String(localized: "today_section_unscheduled", bundle: PresentationResources.bundle),
                        items: items.unscheduled
                    )
            case .focused:
                return TodayFeature.makeSection(
                    category: .focused,
                    title: String(localized: "today_section_focused", bundle: PresentationResources.bundle),
                    items: items.focused
                )
            case .overdue:
                return TodayFeature.makeSection(
                    category: .overdue,
                    title: String(localized: "today_section_overdue", bundle: PresentationResources.bundle),
                    items: items.overdue
                )
            case .dueSoon:
                return TodayFeature.makeSection(
                    category: .dueSoon,
                    title: String.localizedStringWithFormat(
                        String(localized: "today_section_due_soon_format", bundle: PresentationResources.bundle),
                        Int64(TodayFeature.upcomingWindowDays)
                    ),
                    items: items.dueSoon
                )
            }
        }

        var summaryCounts: [SectionScope: Int] {
            let now = Date()
            return Dictionary(
                uniqueKeysWithValues: SectionScope.allCases.map { scope in
                    (
                        scope,
                        TodayFeature.summaryValue(
                            for: scope,
                            todos: todos,
                            displayOptions: displayOptions,
                            now: now
                        )
                    )
                }
            )
        }
    }

    enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case refresh
        case fetchData
        case setSectionScope(SectionScope)
        case resetDisplayOptions
        case completeTodo(TodayTodoItem)
        case togglePinned(TodayTodoItem)
        case store(StoreAction)
        case loading(LoadingFeature.Action)

        enum StoreAction: Equatable {
            case setAlert
            case setTodos([TodayTodoItem])
            case updateTodo(TodayTodoItem)
            case removeTodo(String)
        }
    }

    @Dependency(\.todayFetchTodosUseCase) var fetchTodosUseCase
    @Dependency(\.fetchTodoByIdUseCase) var fetchTodoByIdUseCase
    @Dependency(\.upsertTodoUseCase) var upsertTodoUseCase
    @Dependency(\.updateTodayDisplayOptionsUseCase) var updateTodayDisplayOptionsUseCase
    @Dependency(\.trackAnalyticsEventUseCase) var trackAnalyticsEventUseCase

    static let pageSize = 20
    static let upcomingWindowDays = 7

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .binding(\.displayOptions.dueDateVisibility),
                 .binding(\.displayOptions.focusVisibility),
                 .binding(\.displayOptions.isFocusedOnly):
                return updateDisplayOptionsEffect(state.displayOptions)
            case .binding:
                break
            case .refresh:
                return fetchTodosEffect(showsIndicator: false)
            case .fetchData:
                return fetchTodosEffect()
            case .setSectionScope(let scope):
                if state.selectedSectionScope == scope, scope != .all {
                    state.selectedSectionScope = .all
                } else {
                    state.selectedSectionScope = scope
                }
            case .resetDisplayOptions:
                state.displayOptions = .default
                return updateDisplayOptionsEffect(state.displayOptions)
            case .completeTodo(let item):
                return completeTodoEffect(item)
            case .togglePinned(let item):
                return togglePinnedEffect(item)
            case .store(.setAlert):
                state.alert = Self.alertState()
            case .store(.setTodos(let todos)):
                state.todos = todos
            case .store(.updateTodo(let item)):
                if let index = state.todos.firstIndex(where: { $0.id == item.id }) {
                    state.todos[index] = item
                } else {
                    state.todos.append(item)
                }
            case .store(.removeTodo(let todoId)):
                state.todos.removeAll { $0.id == todoId }
            case .loading:
                break
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension DependencyValues {
    var todayFetchTodosUseCase: FetchTodosUseCase {
        get { self[TodayFetchTodosUseCaseKey.self] }
        set { self[TodayFetchTodosUseCaseKey.self] = newValue }
    }

    var updateTodayDisplayOptionsUseCase: UpdateTodayDisplayOptionsUseCase {
        get { self[UpdateTodayDisplayOptionsUseCaseKey.self] }
        set { self[UpdateTodayDisplayOptionsUseCaseKey.self] = newValue }
    }
}

private enum TodayFetchTodosUseCaseKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }

    static var testValue: FetchTodosUseCase {
        liveValue
    }
}

private enum UpdateTodayDisplayOptionsUseCaseKey: DependencyKey {
    static var liveValue: UpdateTodayDisplayOptionsUseCase {
        preconditionFailure("UpdateTodayDisplayOptionsUseCase must be provided.")
    }

    static var testValue: UpdateTodayDisplayOptionsUseCase {
        liveValue
    }
}

private extension TodayFeature {
    func fetchTodosEffect(showsIndicator: Bool = true) -> Effect<Action> {
        .run { [fetchTodosUseCase] send in
            if showsIndicator {
                await send(.loading(.begin(target: .default, mode: .delayed)))
            }
            do {
                async let todosWithDueDatePage = fetchTodosUseCase.execute(
                    TodoQuery(
                        completionFilter: .incomplete,
                        dueDateFilter: .withDueDate,
                        sortTarget: .dueDate,
                        sortOrder: .oldest,
                        pageSize: Self.pageSize,
                        fetchAllPages: true
                    ),
                    cursor: nil
                )
                async let todosWithoutDueDatePage = fetchTodosUseCase.execute(
                    TodoQuery(
                        completionFilter: .incomplete,
                        dueDateFilter: .withoutDueDate,
                        sortTarget: .updatedAt,
                        sortOrder: .latest,
                        pageSize: Self.pageSize,
                        fetchAllPages: true
                    ),
                    cursor: nil
                )
                let todosWithDueDate = try await todosWithDueDatePage.items.compactMap(TodayTodoItem.init(from:))
                let todosWithoutDueDate = try await todosWithoutDueDatePage.items.compactMap(TodayTodoItem.init(from:))
                await send(.store(.setTodos(todosWithDueDate + todosWithoutDueDate)))
                if showsIndicator {
                    await send(.loading(.end(target: .default, mode: .delayed)))
                }
            } catch {
                if showsIndicator {
                    await send(.loading(.end(target: .default, mode: .delayed)))
                }
                await send(.store(.setAlert))
            }
        }
    }

    func updateDisplayOptionsEffect(_ options: TodayDisplayOptions) -> Effect<Action> {
        .run { [updateTodayDisplayOptionsUseCase] _ in
            updateTodayDisplayOptionsUseCase.execute(options)
        }
    }

    func completeTodoEffect(_ item: TodayTodoItem) -> Effect<Action> {
        .run { [fetchTodoByIdUseCase, upsertTodoUseCase, trackAnalyticsEventUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                var todo = try await fetchTodoByIdUseCase.execute(item.id)
                let now = Date()
                todo.isCompleted = true
                todo.completedAt = now
                todo.updatedAt = now
                try await upsertTodoUseCase.execute(todo)
                trackAnalyticsEventUseCase.execute(.todoComplete)
                await send(.store(.removeTodo(todo.id)))
                await send(.loading(.end(target: .default, mode: .delayed)))
            } catch {
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.store(.setAlert))
            }
        }
    }

    func togglePinnedEffect(_ item: TodayTodoItem) -> Effect<Action> {
        .run { [fetchTodoByIdUseCase, upsertTodoUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                var todo = try await fetchTodoByIdUseCase.execute(item.id)
                todo.isPinned.toggle()
                todo.updatedAt = Date()
                try await upsertTodoUseCase.execute(todo)
                guard let todayTodoItem = TodayTodoItem(from: todo) else {
                    await send(.loading(.end(target: .default, mode: .delayed)))
                    await send(.store(.setAlert))
                    return
                }
                await send(.store(.updateTodo(todayTodoItem)))
                await send(.loading(.end(target: .default, mode: .delayed)))
            } catch {
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.store(.setAlert))
            }
        }
    }

    static func alertState() -> AlertState<Never> {
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
}
