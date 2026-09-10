//
//  HomeView.swift
//  HomeTab
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import Combine
import Domain
import PresentationShared

public struct HomeView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    @State private var path = [HomeRoute]()
    @State private var searchStore: StoreOf<SearchFeature>
    @State private var store: StoreOf<HomeFeature>
    private let isSelected: Bool
    private let windowEvent: TodoEditorWindowEvent

    public init(
        isSelected: Bool,
        windowEvent: TodoEditorWindowEvent
    ) {
        @Dependency(\.homeFetchRecentSearchQueriesUseCase) var fetchRecentSearchQueriesUseCase
        self._store = State(initialValue: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        })
        self._searchStore = State(initialValue: Store(
            initialState: SearchFeature.State(
                recentQueries: fetchRecentSearchQueriesUseCase.execute()
            )
        ) {
            SearchFeature()
        })
        self.isSelected = isSelected
        self.windowEvent = windowEvent
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                todoSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "nav_home", bundle: PresentationResources.bundle))
            .navigationDestination(for: HomeRoute.self, destination: destinationView)
            .toolbar { toolbar }
        }
        .onAppear { store.send(.view(.startObserving)) }
        .onChange(of: isSelected, initial: true) { _, isSelected in
            if isSelected {
                store.send(.view(.fetchData))
            }
        }
        .onReceive(windowEvent.submits) { submit in
            guard case .create(let value) = submit,
                  value.matchesCreate(source: .home) else { return }
            store.send(.view(.todoEditorCreated))
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(
            item: $store.scope(state: \.sheet, action: \.sheet)
                .activePresentation(when: isSelected),
            content: sheetContent
        )
        .fullScreenCover(
            item: $store.scope(state: \.fullScreenCover, action: \.fullScreenCover)
                .activePresentation(when: isSelected),
            content: coverContent
        )
    }

    private var todoSection: some View {
        Section(content: {
            if store.isPreferencesLoading {
                LoadingView()
            } else {
                let preferences = store.preferences
                ForEach(preferences.filter { $0.isVisible }, id: \.id) { item in
                    todoCategoryRow(item)
                        .listRowInsets((EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)))
                }
            }
        }, header: {
            HStack {
                Text("TODO", bundle: PresentationResources.bundle)
                    .foregroundStyle(Color.primary)
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: {
                    store.send(.view(.tapManageTodoCategory))
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundStyle(Color.gray)
                }
            }
            .listRowInsets(EdgeInsets())    //  헤더의 padding 제거
        })
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.send(.store(.setPresentation(.contentPicker, true)))
            } label: {
                Image(systemName: "plus")
            }
            .disabled(!store.isNetworkConnected)
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                store.send(.store(.setPresentation(.searchView, true)))
            } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheetStore: Store<HomeFeature.SheetState, HomeFeature.Sheet>) -> some View {
        if case .contentPicker = sheetStore.state {
            NavigationStack {
                List {
                    Section {
                        if store.isPreferencesLoading {
                            LoadingView()
                        } else {
                            let preferences = store.preferences.filter(\.isVisible)
                            ForEach(preferences, id: \.id) { item in
                                Button {
                                    openTodoEditor(for: item.category)
                                } label: {
                                    labelImage(
                                        text: item.localizedName,
                                        systemName: item.symbolName,
                                        imageColor: item.color
                                    )
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
                        }
                    } header: {
                        Text("TODO", bundle: PresentationResources.bundle)
                            .foregroundStyle(Color(.label))
                    }

                }
                .navigationTitle(Text("TODO"))
                .navigationBarTitleDisplayMode(.inline)  //  설정 안하면 섹션 위에 내비게이션 large 만큼 영역 먹음
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            store.send(.sheet(.presented(.tapCloseButton)))
                        } label: {
                            Image(systemName: "xmark")
                                .bold()
                        }
                    }
                }
            }
        } else if let store = sheetStore.scope(state: \.categoryManageState, action: \.categoryManage) {
            CategoryManageView(store: store)
        }
    }

    @ViewBuilder
    private func coverContent(
        _ coverStore: Store<HomeFeature.FullScreenCoverState, HomeFeature.FullScreenCover>
    ) -> some View {
        switch coverStore.destination {
        case .todoEditor:
            if let todoEditorStore = coverStore.scope(state: \.todoEditor, action: \.todoEditor) {
                TodoEditorView(store: todoEditorStore)
            }
        case .search:
            SearchView(store: searchStore)
        }
    }

    @ViewBuilder
    private func destinationView(_ route: HomeRoute) -> some View {
        switch route {
        case .category(let item):
            TodoListView(
                store: Store(initialState: TodoListFeature.State(category: item.todoCategory)) {
                    TodoListFeature()
                },
                windowEvent: windowEvent,
                onSelectTodo: { path.append(.todo(TodoIdItem(id: $0))) }
            )
            .id(item.id)
        case .todo(let item):
            TodoDetailView(
                store: Store(
                    initialState: TodoDetailFeature.State(todoId: item.id, showEditButton: true)
                ) {
                    TodoDetailFeature()
                },
                windowEvent: windowEvent
            )
            .id(item.id)
        }
    }

    @ViewBuilder
    private func todoCategoryRow(_ item: TodoCategoryItem) -> some View {
        NavigationLink(value: HomeRoute.category(item)) {
            labelImage(
                text: item.localizedName,
                systemName: item.symbolName,
                imageColor: item.color
            )
        }
    }

    private func labelImage(
        text: String,
        systemName: String,
        imageColor: Color
    ) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(imageColor)
                .frame(width: labelWidth, height: labelWidth)
                .overlay {
                    Image(systemName: systemName)
                        .foregroundStyle(Color.white)
                        .font(.title3)
                }
            Text(text)
                .foregroundStyle(Color.primary)
            Spacer()
        }
        .contentShape(.rect)
    }

    private func openTodoEditor(for todoCategory: TodoCategory) {
        if isiOSAppOnMac {
            store.send(.store(.setPresentation(.contentPicker, false)))
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todoCategory: todoCategory, source: .home)
            )
        } else {
            store.send(.view(.tapTodoCategory(todoCategory)))
        }
    }

}

public enum HomeRoute: Hashable {
    case category(TodoCategoryItem)
    case todo(TodoIdItem)
}
