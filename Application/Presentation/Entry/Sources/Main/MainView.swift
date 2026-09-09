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
        tabView
            .onAppear { store.send(.view(.onAppear)) }
            .onChange(of: selectedTab, initial: true) { _, tab in
                store.send(.view(.selectedTabChanged(tab)))
            }
            .prominentAlert(store, state: \.alert, action: \.alert)
            .toastHost()
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                isSelected: selectedTab == .home,
                windowEvent: windowEvent
            )
            .tabItem { tabLabel(.home) }
            .tag(MainTab.home)

            TodayView(
                isSelected: selectedTab == .today,
                windowEvent: windowEvent
            )
            .tabItem { tabLabel(.today) }
            .tag(MainTab.today)

            PushNotificationListView(isSelected: selectedTab == .notification)
                .tabItem { tabLabel(.notification) }
                .badge(store.unreadPushCount)
                .tag(MainTab.notification)

            ProfileView(isSelected: selectedTab == .profile)
                .tabItem { tabLabel(.profile) }
                .tag(MainTab.profile)
        }
    }

    private func tabLabel(_ tab: MainTab) -> some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.symbolName)
        }
    }
}

private extension MainTab {
    var title: String {
        switch self {
        case .home:
            String(localized: "nav_home", bundle: PresentationResources.bundle)
        case .today:
            String(localized: "nav_today", bundle: PresentationResources.bundle)
        case .notification:
            String(localized: "nav_notifications", bundle: PresentationResources.bundle)
        case .profile:
            String(localized: "nav_profile", bundle: PresentationResources.bundle)
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
