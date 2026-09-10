//
//  ProfileRegularDetailView.swift
//  ProfileTab
//
//  Created by opfic on 7/6/26.
//

import SwiftUI
import PresentationShared

public struct ProfileRegularDetailView: View {
    let coordinator: ProfileViewCoordinator

    public init(coordinator: ProfileViewCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        NavigationStack(path: navigationPath) {
            Group {
                if let route = coordinator.router.root {
                    ProfileDestinationView(
                        route: route,
                        coordinator: coordinator,
                        identifiesActivityDetail: true
                    )
                } else {
                    ContentUnavailableView(
                        String(localized: "profile_select_detail", bundle: PresentationResources.bundle),
                        systemImage: "person.crop.circle"
                    )
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                ProfileDestinationView(
                    route: route,
                    coordinator: coordinator,
                    identifiesActivityDetail: true
                )
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var navigationPath: Binding<[ProfileRoute]> {
        Binding(
            get: { coordinator.router.detailPath },
            set: { coordinator.router.detailPath = $0 }
        )
    }
}

struct ProfileDestinationView: View {
    let route: ProfileRoute
    let coordinator: ProfileViewCoordinator
    let identifiesActivityDetail: Bool

    init(
        route: ProfileRoute,
        coordinator: ProfileViewCoordinator,
        identifiesActivityDetail: Bool = false
    ) {
        self.route = route
        self.coordinator = coordinator
        self.identifiesActivityDetail = identifiesActivityDetail
    }

    var body: some View {
        switch route {
        case .settings:
            SettingsView(store: coordinator.settingsStore)
                .environment(coordinator.router)
        case .activity(let todoId):
            activityDetailView(todoId: todoId)
        case .theme:
            @Bindable var settingsStore = coordinator.settingsStore
            ThemeView(theme: $settingsStore.theme)
        case .pushNotification:
            PushNotificationSettingsView(store: coordinator.makePushNotificationSettingsStore())
        case .account:
            AccountView(store: coordinator.makeAccountStore())
        }
    }

    @ViewBuilder
    private func activityDetailView(todoId: String) -> some View {
        if identifiesActivityDetail {
            TodoDetailView(store: coordinator.makeTodoDetailStore(todoId: todoId))
                .id(todoId)
        } else {
            TodoDetailView(store: coordinator.makeTodoDetailStore(todoId: todoId))
        }
    }
}
