//
//  TodoListView.swift
//  PresentationShared
//
//  Created by opfic on 5/30/25.
//

import SwiftUI
import Combine
import ComposableArchitecture
import Core
import Domain

public struct TodoListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @ScaledMetric(relativeTo: .body) private var headerHeight = 41
    @State private var headerOffset: CGFloat = .zero
    @State private var isScrollTrackingEnabled = false
    @State var store: StoreOf<TodoListFeature>
    private let windowEvent: TodoEditorWindowEvent?
    private let onSelectTodo: (String) -> Void

    public init(
        store: StoreOf<TodoListFeature>,
        windowEvent: TodoEditorWindowEvent? = nil,
        onSelectTodo: @escaping (String) -> Void = { _ in }
    ) {
        self.store = store
        self.windowEvent = windowEvent
        self.onSelectTodo = onSelectTodo
    }

    public var body: some View {
        Group {
            if #available(iOS 18, *) {
                if store.state.isSearching {
                    todoSearchContent
                } else {
                    todoListContent
                }
            } else {
                Group {
                    if store.state.isSearching {
                        searchResultsContent
                    } else {
                        todoListContent
                    }
                }
                .searchable(
                    text: $store.searchText,
                    isPresented: $store.isSearching,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(
                        String.localizedStringWithFormat(
                            String(localized: "todo_list_search_prompt_format", bundle: PresentationResources.bundle),
                            TodoCategoryItem(from: store.category).localizedName
                        )
                    )
                )
            }
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .onReceive(windowSubmits) { submit in
            guard case .create(let value) = submit,
                  value.matchesCreate(category: store.category, source: .list) else { return }
            store.send(.view(.windowTodoCreated))
        }
        .navigationTitle(TodoCategoryItem(from: store.category).localizedName)
        .fullScreenCover(
            item: $store.scope(state: \.fullScreenCover, action: \.fullScreenCover)
        ) { coverStore in
            fullScreenCoverContent(coverStore)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openTodoEditor()
                } label: {
                    Image(systemName: "plus")
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            if #available(iOS 18, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.binding(.set(\.isSearching, true)))
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .background(NavigationBarConfigurator())
        .background(Color(.systemGroupedBackground))
        .task { store.send(.view(.onAppear)) }
    }

    private var windowSubmits: AnyPublisher<TodoEditorWindowSubmit, Never> {
        windowEvent?.submits ?? Empty().eraseToAnyPublisher()
    }

    @ViewBuilder
    private var todoListContent: some View {
        let visibleTodos = store.state.todos.filter { !$0.isHidden }

        ZStack {
            List {
                Group {
                    if visibleTodos.isEmpty, !store.state.isLoading {
                        HStack {
                            Spacer()
                            Text(String(localized: "todo_list_empty", bundle: PresentationResources.bundle))
                                .foregroundStyle(Color.gray)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(Array(zip(visibleTodos.indices, visibleTodos)), id: \.1.id) { idx, todo in
                            Button {
                                selectTodo(todo.id)
                            } label: {
                                TodoItemRow(todo)
                            }
                            .todoDetailPreview(todoId: todo.id)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .alignmentGuide(.listRowSeparatorLeading) { _ in return 0 }
                            .overlay(alignment: .top) {
                                if #available(iOS 26.0, *) {
                                    if idx == 0 {
                                        Divider()
                                            .padding(.horizontal, -16)
                                    }
                                }
                            }
                            .onAppear {
                                let lastID = visibleTodos.last?.id
                                if todo.id == lastID, store.state.hasMore {
                                    store.send(.view(.loadNextPage))
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button(action: {
                                    store.send(.view(.tapTogglePinned(todo)))
                                }) {
                                    Image(systemName: "star\(todo.isPinned ? ".slash" : ".fill")")
                                }
                                .tint(Color.orange)
                                Button {
                                    store.send(.view(.tapToggleCompleted(todo)))
                                } label: {
                                    Image(systemName: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(Color.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive, action: {
                                    store.send(.view(.swipeTodo(todo)))
                                    presentDeleteTodoToast(todo.id)
                                }) {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden, edges: .top)
            }
            .listStyle(.plain)
            .onScrollOffsetChange { offset in
                guard isScrollTrackingEnabled else { return }
                headerOffset = max(0, -offset)
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 4) {
                    headerView
                    if #unavailable(iOS 26) {
                        Divider()
                            .padding(.horizontal, -16)
                    }
                }
                .background {
                    if #available(iOS 26.0, *) {
                        Color.clear
                    } else {
                        Color(.systemGroupedBackground)
                    }
                }
                .offset(y: headerOffset)
            }
            .refreshable { await store.send(.view(.refresh)).finish() }
            .scrollDisabled(visibleTodos.isEmpty || store.state.isLoading)

            if store.state.isLoading {
                LoadingView()
            }
        }
    }

    @available(iOS 18, *)
    private var todoSearchContent: some View {
        searchResultsContent
            .searchable(
                text: $store.searchText,
                isPresented: $store.isSearching,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(
                    String.localizedStringWithFormat(
                        String(localized: "todo_list_search_prompt_format", bundle: PresentationResources.bundle),
                        TodoCategoryItem(from: store.category).localizedName
                    )
                )
            )
    }

    @ViewBuilder
    private func fullScreenCoverContent(
        _ coverStore: Store<
        TodoListFeature.FullScreenCoverState,
        TodoListFeature.Action.FullScreenCover>
    ) -> some View {
        switch coverStore.destination {
        case .editor:
            if let todoEditorStore = coverStore.scope(state: \.todoEditor, action: \.todoEditor) {
                TodoEditorView(store: todoEditorStore)
            }
        }
    }

    private func openTodoEditor() {
        if isiOSAppOnMac {
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todoCategory: store.category, source: .list)
            )
        } else {
            store.send(.store(.setFullScreenCover(.editor)))
        }
    }

    private func presentDeleteTodoToast(_ todoId: String) {
        ToastPresenter.present(
            message: String(localized: "common_undo", bundle: PresentationResources.bundle),
            systemImage: "arrow.uturn.left",
            duration: 5,
            action: {
                store.send(.view(.undoDelete))
            },
            onDismiss: {
                store.send(.view(.finishDeleteToast(todoId)))
            }
        )
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        let searchResults = store.state.searchResults.filter { !$0.isHidden }
        let limit = store.searchResultsLimit
        let displayedTodos = store.state.showAllSearchResults
            ? searchResults
            : Array(searchResults.prefix(limit))

        if store.state.searchText.isEmpty {
            Text(
                String.localizedStringWithFormat(
                    String(localized: "todo_list_search_instruction_format", bundle: PresentationResources.bundle),
                    TodoCategoryItem(from: store.category).localizedName
                )
            )
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
        } else if store.state.isLoading {
            LoadingView()
        } else if searchResults.isEmpty {
            Spacer()
            Text(String(localized: "todo_list_search_empty", bundle: PresentationResources.bundle))
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(displayedTodos) { todo in
                        Button {
                            selectTodo(todo.id)
                        } label: {
                            VStack(spacing: 0) {
                                TodoItemRow(todo)
                                Divider()
                            }
                        }
                        .todoDetailPreview(todoId: todo.id)
                    }
                    .padding(.horizontal, 16)

                    if !store.state.showAllSearchResults, limit < searchResults.count {
                        Button(String(localized: "todo_list_show_more", bundle: PresentationResources.bundle)) {
                            store.send(.binding(.set(\.showAllSearchResults, true)))
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private var headerView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if 0 < store.appliedFilterCount {
                    Menu {
                        Text(
                            String.localizedStringWithFormat(
                                String(
                                    localized: "todo_list_filters_applied_format",
                                    bundle: PresentationResources.bundle
                                ),
                                Int64(store.appliedFilterCount)
                            )
                        )
                        Button(role: .destructive) {
                            store.send(.view(.resetFilters))
                        } label: {
                            Text(String(localized: "todo_list_clear_filters", bundle: PresentationResources.bundle))
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease")
                            filterBadge
                        }
                        .adaptiveButtonStyle()
                    }
                }

                Menu {
                    Picker(selection: $store.query.sortTarget) {
                        ForEach([TodoQuery.SortTarget.createdAt, .updatedAt], id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    } label: {
                        Text(String(localized: "todo_list_sort_by", bundle: PresentationResources.bundle))
                    }
                    Picker(selection: $store.query.sortOrder) {
                        ForEach([TodoQuery.SortOrder.latest, .oldest], id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    } label: {
                        Text(String(localized: "todo_list_sort_order", bundle: PresentationResources.bundle))
                    }
                } label: {
                    let condition = store.state.query.sortTarget == .createdAt && store.state.query.sortOrder == .latest
                    HStack {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "todo_list_sort_format", bundle: PresentationResources.bundle),
                                store.state.query.sortTarget.title,
                                store.state.query.sortOrder.title
                            )
                        )
                        Image(systemName: "chevron.down")
                    }
                    .foregroundStyle(condition ? Color(.label) : .white)
                    .adaptiveButtonStyle(color: condition ? .clear : .blue)
                }

                Menu {
                    Toggle(isOn: $store.query.isPinned) {
                        Text(String(localized: "todo_pinned", bundle: PresentationResources.bundle))
                    }

                    Picker(selection: $store.query.completionFilter) {
                        ForEach([TodoQuery.CompletionFilter.all, .incomplete, .completed], id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    } label: {
                        Text(String(localized: "todo_list_completion_status", bundle: PresentationResources.bundle))
                    }
                } label: {
                    let condition = store.state.query.isPinned || store.state.query.completionFilter != .all
                    HStack {
                        Text(String(localized: "todo_list_filter_options", bundle: PresentationResources.bundle))
                        Image(systemName: "chevron.down")
                    }
                    .foregroundStyle(condition ? .white : Color(.label))
                    .adaptiveButtonStyle(color: condition ? .blue : .clear)
                }
            }
        }
        .scrollIndicators(.never)
        .scrollDisabled(!isScrollTrackingEnabled)
        .contentMargins(.leading, 16, for: .scrollContent)
        .frame(height: headerHeight)
        .onAppear {
            headerOffset = 0
            isScrollTrackingEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isScrollTrackingEnabled = true
            }
        }
    }

    private var filterBadge: some View {
        let isDark = colorScheme == .dark
        let blue = Color(uiColor: .systemBlue)
        let textColor: Color = isDark ? blue : .white
        let backgroundColor: Color = isDark ? .white : blue

        return Text("\(store.appliedFilterCount)")
            .font(.caption2.weight(.bold))
            .foregroundColor(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: 20, height: 20)
            .background(Circle().fill(backgroundColor))
    }

    private func selectTodo(_ todoId: String) {
        onSelectTodo(todoId)
    }
}
