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
        TabView(selection: $selectedTab) {
            Tab(value: MainTab.home) {
                tabContent(.home)
            } label: {
                tabLabel(.home)
            }
            Tab(value: MainTab.today) {
                tabContent(.today)
            } label: {
                tabLabel(.today)
            }
            Tab(value: MainTab.notification) {
                tabContent(.notification)
            } label: {
                tabLabel(.notification)
            }
            .badge(store.unreadPushCount)
            Tab(value: MainTab.profile) {
                tabContent(.profile)
            } label: {
                tabLabel(.profile)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .toastHost()
        .onAppear { store.send(.view(.onAppear)) }
        .onChange(of: selectedTab, initial: true) { _, tab in
            store.send(.view(.selectedTabChanged(tab)))
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
    }

    @ViewBuilder
    private func tabContent(_ tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        tabView(tab, isSelected: isSelected)
            .environment(\.isTabContentActive, isSelected)
    }

    private func tabLabel(_ tab: MainTab) -> some View {
        Label(tab.title, systemImage: tab.symbolName)
    }

    @ViewBuilder
    private func tabView(_ tab: MainTab, isSelected: Bool) -> some View {
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
            ProfileView(
                isSelected: isSelected,
                windowEvent: windowEvent
            )
        }
    }
}
