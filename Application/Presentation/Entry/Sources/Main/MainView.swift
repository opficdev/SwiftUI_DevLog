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
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
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
        HStack(spacing: 0) {
            if showsSideBar {
                SideBar(
                    selectedTab: $selectedTab,
                    unreadPushCount: store.unreadPushCount
                )
                .resizableSideBar(
                    minimumWidth: 220,
                    idealWidth: 260,
                    maximumWidth: 320
                )
            }

            TabView(selection: $selectedTab) {
                Tab(
                    MainTab.home.title,
                    systemImage: MainTab.home.symbolName,
                    value: MainTab.home
                ) {
                    tabContent(.home)
                }
                Tab(
                    MainTab.today.title,
                    systemImage: MainTab.today.symbolName,
                    value: MainTab.today
                ) {
                    tabContent(.today)
                }
                Tab(
                    MainTab.notification.title,
                    systemImage: MainTab.notification.symbolName,
                    value: MainTab.notification
                ) {
                    tabContent(.notification)
                }
                .badge(store.unreadPushCount)
                Tab(
                    MainTab.profile.title,
                    systemImage: MainTab.profile.symbolName,
                    value: MainTab.profile
                ) {
                    tabContent(.profile)
                }
            }
        }
        .toastHost()
        .onAppear { store.send(.view(.onAppear)) }
        .onChange(of: selectedTab, initial: true) { _, tab in
            store.send(.view(.selectedTabChanged(tab)))
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
    }

    private var showsSideBar: Bool {
        isiOSAppOnMac || horizontalSizeClass == .regular
    }

    @ViewBuilder
    private func tabContent(_ tab: MainTab) -> some View {
        let isSelected = selectedTab == tab
        tabView(tab, isSelected: isSelected)
            .environment(\.isTabContentActive, isSelected)
            .toolbarVisibility(showsSideBar ? .hidden : .visible, for: .tabBar)
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

private struct SideBar: View {
    @Binding var selectedTab: MainTab
    let unreadPushCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background {
            Color.surface
                .ignoresSafeArea(.container, edges: .vertical)
        }
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab.symbolName)
                    .font(.title3)
                    .frame(width: 24)
                Text(tab.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                if tab == .notification, 0 < unreadPushCount {
                    Text(verbatim: unreadPushCount.formatted())
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accent, in: .capsule)
                }
            }
            .foregroundStyle(isSelected ? Color.onPrimaryContainer : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primaryContainer : .clear)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct ResizableSideBarModifier: ViewModifier {
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var width: CGFloat
    @State private var dragStartWidth: CGFloat?
    private let minimumWidth: CGFloat
    private let maximumWidth: CGFloat

    init(
        minimumWidth: CGFloat,
        idealWidth: CGFloat,
        maximumWidth: CGFloat
    ) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = maximumWidth
        self._width = State(initialValue: min(max(idealWidth, minimumWidth), maximumWidth))
    }

    func body(content: Content) -> some View {
        content
            .frame(width: width)
            .overlay(alignment: .trailing) {
                Color.clear
                    .frame(width: 16)
                    .contentShape(.rect)
                    .gesture(resizeGesture)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Color.border)
                            .frame(width: 1)
                    }
                    .ignoresSafeArea(.container, edges: .vertical)
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if dragStartWidth == nil {
                    dragStartWidth = width
                }
                let startWidth = dragStartWidth ?? width
                let translation = layoutDirection == .leftToRight
                    ? value.translation.width
                    : -value.translation.width
                width = min(max(startWidth + translation, minimumWidth), maximumWidth)
            }
            .onEnded { _ in
                dragStartWidth = nil
            }
    }
}

private extension View {
    func resizableSideBar(
        minimumWidth: CGFloat,
        idealWidth: CGFloat,
        maximumWidth: CGFloat
    ) -> some View {
        modifier(ResizableSideBarModifier(
            minimumWidth: minimumWidth,
            idealWidth: idealWidth,
            maximumWidth: maximumWidth
        ))
    }
}
