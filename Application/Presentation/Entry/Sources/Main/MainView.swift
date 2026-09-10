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
        self._selectedTab = selectedTab
        self.windowEvent = windowEvent
    }

    var body: some View {
        ExposableTabContent(
            selection: $selectedTab,
            items: MainTab.allCases,
            content: tabContent
        )
        .toastHost()
        .exposableTabBar(isPresented: !usesSidebar) {
            MainTabBar(
                selectedTab: $selectedTab,
                unreadPushCount: store.unreadPushCount
            )
        }
        .exposableSideBar(
            isPresented: sidebarPresentation,
            showsToggle: usesSidebar
        ) {
            MainSideBar(
                selectedTab: $selectedTab,
                unreadPushCount: store.unreadPushCount
            )
        }
        .onAppear { store.send(.view(.onAppear)) }
        .onChange(of: selectedTab, initial: true) { _, tab in
            store.send(.view(.selectedTabChanged(tab)))
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
    }

    @ViewBuilder
    private func tabContent(_ tab: MainTab, isSelected: Bool) -> some View {
        switch tab {
        case .home:
            HomeView(
                isSelected: isSelected,
                windowEvent: windowEvent
            )
        case .today:
            TodayView(
                isSelected: isSelected,
                windowEvent: windowEvent
            )
        case .notification:
            PushNotificationListView(isSelected: isSelected)
        case .profile:
            ProfileView(isSelected: isSelected)
        }
    }

    private var usesSidebar: Bool {
        horizontalSizeClass == .regular
    }

    private var sidebarPresentation: Binding<Bool> {
        Binding(
            get: { usesSidebar && store.isSidebarPresented },
            set: { store.send(.view(.setSidebarPresented($0))) }
        )
    }
}
