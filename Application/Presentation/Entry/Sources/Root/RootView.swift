//
//  RootView.swift
//  Entry
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import Combine
import PresentationShared

public struct RootView: View {
    @State private var store: StoreOf<RootFeature>
    private let widgetURLTab: (URL) -> MainTab?
    private let windowEvent: TodoEditorWindowEvent
    private let pushNotificationTodoIdPublisher: AnyPublisher<String, Never>
    private let clearPushNotificationRoute: () -> Void

    public init(
        widgetURLTab: @escaping (URL) -> MainTab?,
        windowEvent: TodoEditorWindowEvent,
        pushNotificationTodoIdPublisher: AnyPublisher<String, Never>,
        clearPushNotificationRoute: @escaping () -> Void
    ) {
        self._store = State(initialValue: Store(initialState: RootFeature.State()) {
            RootFeature()
        })
        self.widgetURLTab = widgetURLTab
        self.windowEvent = windowEvent
        self.pushNotificationTodoIdPublisher = pushNotificationTodoIdPublisher
        self.clearPushNotificationRoute = clearPushNotificationRoute
    }

    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if let signIn = store.signIn {
                if signIn {
                    MainView(
                        windowEvent: windowEvent,
                        selectedTab: $store.selectedMainTab
                    )
                } else {
                    LoginView()
                }
            }
        }
        .preferredColorScheme(store.theme.colorScheme)
        .onAppear { store.send(.onAppear) }
        .onOpenURL { url in
            guard let mainTab = widgetURLTab(url) else { return }
            store.send(.openWidgetRoute(mainTab))
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(item: $store.scope(state: \.sheet, action: \.sheet)) { sheetStore in
            sheetContent(todoId: sheetStore.todoId) {
                sheetStore.send(.tapCloseButton)
            }
        }
        .onReceive(pushNotificationTodoIdPublisher) { todoId in
            store.send(.presentTodoDetail(todoId))
            clearPushNotificationRoute()
        }
    }

    private func sheetContent(
        todoId: String,
        onClose: @escaping () -> Void
    ) -> some View {
        NavigationStack {
            TodoDetailView(store: Store(
                initialState: TodoDetailFeature.State(todoId: todoId, showEditButton: false)
            ) {
                TodoDetailFeature()
            })
            .toolbar {
                ToolbarLeadingButton {
                    onClose()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .presentationDragIndicator(.visible)
    }
}
