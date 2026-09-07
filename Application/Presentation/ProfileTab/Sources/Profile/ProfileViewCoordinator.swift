//
//  ProfileViewCoordinator.swift
//  ProfileTab
//
//  Created by opfic on 5/21/26.
//

import Foundation
import Domain
import PresentationShared

@MainActor
@Observable
public final class ProfileViewCoordinator {
    let store: StoreOf<ProfileFeature>
    let settingsStore: StoreOf<SettingsFeature>
    var router = NavigationRouter<ProfileRoute>()

    public init() {
        self.store = Store(initialState: ProfileFeature.State()) {
            ProfileFeature()
        }
        self.settingsStore = Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        self.store.send(.startObserving)
        self.settingsStore.send(.startObserving)
    }

    public func fetchData() {
        store.send(.fetchData)
    }

    func makeAccountStore() -> StoreOf<AccountFeature> {
        Store(initialState: AccountFeature.State()) {
            AccountFeature()
        }
    }

    func makePushNotificationSettingsStore() -> StoreOf<PushNotificationSettingsFeature> {
        Store(initialState: PushNotificationSettingsFeature.State()) {
            PushNotificationSettingsFeature()
        }
    }

    func makeTodoDetailStore(todoId: String) -> StoreOf<TodoDetailFeature> {
        Store(
            initialState: TodoDetailFeature.State(
                todoId: todoId,
                showEditButton: false
            )
        ) {
            TodoDetailFeature()
        }
    }
}
