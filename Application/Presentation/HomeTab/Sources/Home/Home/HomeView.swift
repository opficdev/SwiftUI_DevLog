//
//  HomeView.swift
//  HomeTab
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import Domain
import PresentationShared

public struct HomeView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    @Bindable var store: StoreOf<HomeFeature>
    let coordinator: HomeViewCoordinator
    let isCompactLayout: Bool

    public init(
        coordinator: HomeViewCoordinator,
        isCompactLayout: Bool
    ) {
        self.coordinator = coordinator
        self.isCompactLayout = isCompactLayout
        self.store = coordinator.store
    }

    public var body: some View {
        List {
            todoSection
            recentTodoSection
            webPageSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "nav_home", bundle: PresentationResources.bundle))
        .toolbar { toolbar }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(item: $store.scope(state: \.sheet, action: \.sheet), content: sheetContent)
        .fullScreenCover(item: $store.scope(state: \.fullScreenCover, action: \.fullScreenCover), content: coverContent)
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

    private var recentTodoSection: some View {
        Section {
            if store.isRecentTodosLoading && store.recentTodos.isEmpty {
                LoadingView()
            } else if store.recentTodos.isEmpty {
                HStack {
                    Spacer()
                    Text(String(localized: "home_recent_empty", bundle: PresentationResources.bundle))
                        .font(.callout)
                    Spacer()
                }
            } else {
                ForEach(store.recentTodos, id: \.id) { todo in
                    recentTodoRow(todo)
                }
            }
        } header: {
            HStack {
                Text(String(localized: "home_recent_title", bundle: PresentationResources.bundle))
                    .foregroundStyle(Color.primary)
                    .font(.title2.bold())
                Spacer()
            }
            .listRowInsets(EdgeInsets())
        }
    }

    private var webPageSection: some View {
        Section {
            let webPages = store.webPages.filter { !$0.isHidden }
            if store.isWebPageLoading {
                LoadingView()
                    .id(UUID()) //  id 부여를 통해 렌더링 강제
            } else if store.needsWebPageRefresh {
                Button {
                    store.send(.view(.refreshWebPages))
                } label: {
                    HStack {
                        Spacer()
                        Text(String(localized: "home_web_refresh_required", bundle: PresentationResources.bundle))
                            .font(.callout)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } else if webPages.isEmpty {
                HStack {
                    Spacer()
                    Text(String(localized: "home_web_empty", bundle: PresentationResources.bundle))
                        .font(.callout)
                    Spacer()
                }
            } else {
                ForEach(webPages, id: \.id) { page in
                    webResultRow(page)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        } header: {
            HStack {
                Text("Web Page", bundle: PresentationResources.bundle)
                    .foregroundStyle(Color.primary)
                    .font(.title2.bold())
                Spacer()
            }
            .listRowInsets(EdgeInsets())
        }
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
        if let pickerStore = sheetStore.scope(state: \.contentPickerState, action: \.contentPicker) {
            @Bindable var pickerStore = pickerStore
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

                    Section {
                        Button {
                            pickerStore.send(.tapWebPageInput)
                        } label: {
                            labelImage(
                                text: "URL",
                                systemName: "globe",
                                imageColor: .blue
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    } header: {
                        Text("Web Page", bundle: PresentationResources.bundle)
                            .foregroundStyle(Color(.label))
                    }
                }
                .navigationDestination(
                    item: $pickerStore.scope(state: \.webPageInput, action: \.webPageInput)
                ) { _ in
                    Form {
                        Section {
                            TextField(
                                "",
                                text: $store.webPageURLInput,
                                prompt: Text("https://", bundle: PresentationResources.bundle)
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                        } footer: {
                            Text(String(localized: "home_webpage_input_message", bundle: PresentationResources.bundle))
                        }
                    }
                    .scrollDisabled(true)
                    .navigationTitle(
                        Text(
                            String(
                                localized: "home_webpage_input_title",
                                bundle: PresentationResources.bundle
                            )
                        )
                    )
                    .navigationBarTitleDisplayMode(.inline) //  설정 안하면 섹션 위에 내비게이션 large 만큼 영역 먹음
                    .toolbar {
                        if store.isAppending {
                            if #available(iOS 26.0, *) {
                                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                ProgressView()
                            }
                        } else {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(String(localized: "home_add", bundle: PresentationResources.bundle)) {
                                    store.send(.view(.addWebPage))
                                }
                            }
                        }
                    }
                }
                .navigationTitle(Text(String(localized: "nav_home_content", bundle: PresentationResources.bundle)))
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
            SearchView(store: coordinator.makeSearchStore())
        }
    }

    @ViewBuilder
    private func todoCategoryRow(_ item: TodoCategoryItem) -> some View {
        if isCompactLayout {
            NavigationLink(value: HomeRoute.category(item)) {
                labelImage(
                    text: item.localizedName,
                    systemName: item.symbolName,
                    imageColor: item.color
                )
            }
        } else {
            Button {
                coordinator.router.replace(with: .category(item))
            } label: {
                labelImage(
                    text: item.localizedName,
                    systemName: item.symbolName,
                    imageColor: item.color
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func recentTodoRow(_ item: RecentTodoItem) -> some View {
        Group {
            if isCompactLayout {
                NavigationLink(value: HomeRoute.todo(TodoIdItem(id: item.id))) {
                    RecentTodoRow(todo: item)
                }
            } else {
                Button {
                    coordinator.router.replace(with: .todo(TodoIdItem(id: item.id)))
                } label: {
                    RecentTodoRow(todo: item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .todoDetailPreview(todoId: item.id)
    }

    @ViewBuilder
    private func webResultRow(_ item: WebPageItem) -> some View {
        Group {
            if isCompactLayout {
                NavigationLink(value: HomeRoute.webPage(item)) {
                    WebItemRow(item: item, showsChevron: false)
                }
            } else {
                Button {
                    coordinator.router.replace(with: .webPage(item))
                } label: {
                    WebItemRow(item: item, showsChevron: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.send(.view(.deleteWebPage(item)))
                presentDeleteWebPageToast(item.url.absoluteString)
            } label: {
                Label(String(localized: "common_delete", bundle: PresentationResources.bundle), systemImage: "trash")
            }
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

    private func presentDeleteWebPageToast(_ urlString: String) {
        ToastPresenter.present(
            message: String(localized: "common_undo", bundle: PresentationResources.bundle),
            systemImage: "arrow.uturn.left",
            duration: 5,
            font: .caption,
            multilineTextAlignment: .center,
            action: {
                store.send(.view(.undoDeleteWebPage))
            },
            onDismiss: {
                store.send(.view(.finishDeleteWebPageToast(urlString)))
            }
        )
    }

}

public enum HomeRoute: Hashable {
    case category(TodoCategoryItem)
    case todo(TodoIdItem)
    case webPage(WebPageItem)
}

private struct RecentTodoRow: View {
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let todo: RecentTodoItem

    var body: some View {
        let category = TodoCategoryItem(from: todo.category)
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(category.color)
                .frame(width: labelWidth, height: labelWidth)
                .overlay {
                    Image(systemName: category.symbolName)
                        .foregroundStyle(Color.white)
                        .font(.title3)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if todo.isPinned {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    Text(todo.title)
                        .foregroundStyle(Color.primary)
                        .font(.headline)
                        .lineLimit(1)
                    Text("#\(todo.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: true, vertical: false)
                }

                HStack(spacing: 6) {
                    Text(category.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.color)

                    RelativeTimeText(date: todo.updatedAt)
                }

                if !todo.tags.isEmpty {
                    TagList(todo.tags, lineLimit: 1)
                }
            }
        }
    }
}
