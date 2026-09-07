//
//  MainView.swift
//  Entry
//
//  Created by opfic on 5/8/25.
//

import SwiftUI
import HomeTab
import NotificationTab
import ProfileTab
import PresentationShared
import TodayTab

struct MainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var todoWindowCoordinator: TodoWindowCoordinator
    @State private var homeViewCoordinator: HomeViewCoordinator
    @State private var todayViewCoordinator: TodayViewCoordinator
    @State private var pushNotificationListViewCoordinator: PushNotificationListViewCoordinator
    @State private var profileViewCoordinator: ProfileViewCoordinator
    @Binding var selectedTab: MainTab
    @State private var store: StoreOf<MainFeature>
    private let windowEvent: TodoEditorWindowEvent

    init(
        windowEvent: TodoEditorWindowEvent,
        selectedTab: Binding<MainTab>
    ) {
        self._store = State(initialValue: Store(initialState: MainFeature.State()) {
            MainFeature()
        })
        self._todoWindowCoordinator = State(initialValue: TodoWindowCoordinator())
        self._homeViewCoordinator = State(initialValue: HomeViewCoordinator())
        self._todayViewCoordinator = State(initialValue: TodayViewCoordinator())
        self._pushNotificationListViewCoordinator = State(
            initialValue: PushNotificationListViewCoordinator()
        )
        self._profileViewCoordinator = State(initialValue: ProfileViewCoordinator())

        self._selectedTab = selectedTab
        self.windowEvent = windowEvent
    }

    var body: some View {
        Group {
            if isCompactLayout {
                tabView
            } else {
                sidebarView(for: selectedTab)
            }
        }
        .onAppear {
            store.send(.view(.onAppear))
            homeViewCoordinator.bindTodoMutationEvent()
            homeViewCoordinator.bindWindowEvent(windowEvent)
            todoWindowCoordinator.bindWindowEvent(windowEvent)
        }
        .onChange(of: selectedTab, initial: true) { _, newValue in
            store.send(.view(.selectedTabChanged(newValue)))
            if newValue == .home {
                homeViewCoordinator.fetchData()
            } else if newValue == .today {
                todayViewCoordinator.fetchData()
            } else if newValue == .notification {
                pushNotificationListViewCoordinator.fetchData()
            } else if newValue == .profile {
                profileViewCoordinator.fetchData()
            }
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .toastHost()
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            homeView
                .tabItem {
                    tabLabel(.home)
                }
                .tag(MainTab.home)

            todayView
                .tabItem {
                    tabLabel(.today)
                }
                .tag(MainTab.today)

            notificationView
                .tabItem {
                    tabLabel(.notification)
                }
                .badge(store.unreadPushCount)
                .tag(MainTab.notification)

            profileView
                .tabItem {
                    tabLabel(.profile)
                }
                .tag(MainTab.profile)
        }
    }

    @ViewBuilder
    private func sidebarView(for selectedTab: MainTab) -> some View {
        switch selectedTab {
        case .home:
            NavigationSplitView {
                mainSidebar
            } content: {
                homeView
                    .navigationSplitViewColumnWidth(min: 350, ideal: 450, max: nil)
            } detail: {
                homeRegularDetailView
            }
            .environment(homeViewCoordinator.router)
        case .today:
            NavigationSplitView {
                mainSidebar
            } content: {
                todayView
                    .navigationSplitViewColumnWidth(min: 350, ideal: 450, max: nil)
            } detail: {
                todayRegularDetailView
            }
        case .notification:
            NavigationSplitView {
                mainSidebar
            } content: {
                PushNotificationListView(
                    coordinator: pushNotificationListViewCoordinator,
                    isCompactLayout: isCompactLayout
                )
                .navigationSplitViewColumnWidth(min: 350, ideal: 450, max: nil)
            } detail: {
                notificationRegularDetailView
            }
        case .profile:
            NavigationSplitView {
                mainSidebar
            } content: {
                profileView
                    .navigationSplitViewColumnWidth(min: 350, ideal: 450, max: nil)
            } detail: {
                profileRegularDetailView
            }
        }
    }

    private var mainSidebar: some View {
        List(selection: sidebarSelection) {
            sidebarRow(.home)
            sidebarRow(.today)
            sidebarRow(.notification)
            sidebarRow(.profile)
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func sidebarRow(_ tab: MainTab) -> some View {
        if tab == .notification {
            tabLabel(tab)
                .badge(store.unreadPushCount)
                .tag(tab)
        } else {
            tabLabel(tab)
                .tag(tab)
        }
    }

    private func tabLabel(_ tab: MainTab) -> some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.symbolName)
        }
    }

    @ViewBuilder
    private var homeView: some View {
        Group {
            if isCompactLayout {
                NavigationStack(path: homeNavigationPath) {
                    homeContentView
                        .navigationDestination(for: HomeRoute.self) { homeRoute in
                            homeDestinationView(homeRoute)
                        }
                }
            } else {
                homeContentView
            }
        }
        .environment(homeViewCoordinator.router)
    }

    private var homeContentView: some View {
        HomeView(
            coordinator: homeViewCoordinator,
            isCompactLayout: isCompactLayout
        )
    }

    @ViewBuilder
    private var homeRegularDetailView: some View {
        NavigationStack(path: homeDetailPath) {
            Group {
                if let homeRoute = homeViewCoordinator.router.root {
                    homeDestinationView(homeRoute)
                } else {
                    ContentUnavailableView(
                        String(localized: "home_select_detail"),
                        systemImage: "house"
                    )
                }
            }
            .navigationDestination(for: HomeRoute.self) { homeRoute in
                homeDestinationView(homeRoute)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func homeDestinationView(_ homeRoute: HomeRoute) -> some View {
        switch homeRoute {
        case .category(let item):
            TodoListView(
                store: todoWindowCoordinator.makeListStore(category: item.todoCategory),
                onSelectTodo: { todoId in
                    homeViewCoordinator.router.push(.todo(TodoIdItem(id: todoId)))
                }
            )
            .id(item.id)
        case .todo(let item):
            TodoDetailView(store: todoWindowCoordinator.makeDetailStore(todoId: item.id))
            .id(item.id)
        case .webPage(let item):
            WebView(url: item.url)
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea()
                .toolbar(.hidden, for: .tabBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(item.title)
                            .bold()
                    }
            }
        }
    }

    @ViewBuilder
    private var todayView: some View {
        Group {
            if isCompactLayout {
                NavigationStack(path: todayNavigationPath) {
                    todayContentView
                        .navigationDestination(for: TodayRoute.self) { todayRoute in
                            todayDestinationView(todayRoute)
                        }
                }
            } else {
                todayContentView
            }
        }
    }

    private var todayContentView: some View {
        TodayView(
            coordinator: todayViewCoordinator,
            isCompactLayout: isCompactLayout
        )
    }

    @ViewBuilder
    private var todayRegularDetailView: some View {
        NavigationStack(path: todayDetailPath) {
            Group {
                if let todayRoute = todayViewCoordinator.router.root {
                    todayDestinationView(todayRoute)
                } else {
                    ContentUnavailableView(
                        String(localized: "today_select_detail"),
                        systemImage: "sun.max"
                    )
                }
            }
            .navigationDestination(for: TodayRoute.self) { todayRoute in
                todayDestinationView(todayRoute)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func todayDestinationView(_ todayRoute: TodayRoute) -> some View {
        switch todayRoute {
        case .todo(let item):
            TodoDetailView(store: todoWindowCoordinator.makeDetailStore(todoId: item.id))
                .id(item.id)
        }
    }

    private var notificationView: some View {
        PushNotificationListView(
            coordinator: pushNotificationListViewCoordinator,
            isCompactLayout: isCompactLayout
        )
    }

    @ViewBuilder
    private var notificationRegularDetailView: some View {
        if let todoId = pushNotificationListViewCoordinator.selectedTodoId {
            TodoDetailView(
                store: pushNotificationListViewCoordinator.makeTodoDetailStore(
                    todoId: todoId
                )
            )
            .id(todoId)
        } else {
            ContentUnavailableView(
                String(localized: "push_notifications_select_detail"),
                systemImage: "bell.badge"
            )
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private var profileView: some View {
        ProfileView(
            coordinator: profileViewCoordinator,
            isCompactLayout: isCompactLayout
        )
    }

    private var profileRegularDetailView: some View {
        ProfileRegularDetailView(coordinator: profileViewCoordinator)
    }
}

private extension MainView {
    var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var sidebarSelection: Binding<MainTab?> {
        Binding(
            get: { selectedTab },
            set: { tab in
                if let tab {
                    selectedTab = tab
                }
            }
        )
    }

    var homeNavigationPath: Binding<[HomeRoute]> {
        Binding(
            get: { homeViewCoordinator.router.path },
            set: { homeViewCoordinator.router.path = $0 }
        )
    }

    var homeDetailPath: Binding<[HomeRoute]> {
        Binding(
            get: { homeViewCoordinator.router.detailPath },
            set: { homeViewCoordinator.router.detailPath = $0 }
        )
    }

    var todayNavigationPath: Binding<[TodayRoute]> {
        Binding(
            get: { todayViewCoordinator.router.path },
            set: { todayViewCoordinator.router.path = $0 }
        )
    }

    var todayDetailPath: Binding<[TodayRoute]> {
        Binding(
            get: { todayViewCoordinator.router.detailPath },
            set: { todayViewCoordinator.router.detailPath = $0 }
        )
    }

}
private extension MainTab {
    var title: String {
        switch self {
        case .home:
            String(localized: "nav_home")
        case .today:
            String(localized: "nav_today")
        case .notification:
            String(localized: "nav_notifications")
        case .profile:
            String(localized: "nav_profile")
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            "house.fill"
        case .today:
            "sun.max.fill"
        case .notification:
            "bell.fill"
        case .profile:
            "person.crop.circle.fill"
        }
    }
}
