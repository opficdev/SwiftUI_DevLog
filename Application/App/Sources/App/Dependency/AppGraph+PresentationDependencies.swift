//
//  AppGraph+PresentationDependencies.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Presentation

extension AppGraph {
    func preparePresentationDependencies() {
        prepareDependencies { dependencies in
            prepareEntryDependencies(&dependencies)
            prepareTodoDependencies(&dependencies)
            prepareHomeDependencies(&dependencies)
            prepareTodayDependencies(&dependencies)
            prepareNotificationDependencies(&dependencies)
            prepareProfileDependencies(&dependencies)
        }
    }
}

private extension AppGraph {
    func prepareEntryDependencies(_ dependencies: inout DependencyValues) {
        PresentationDependencyPreparation.prepareRoot(
            &dependencies,
            sessionUseCase: authenticationGraphSet.authSessionUseCaseGraph.observeAuthSessionUseCase,
            networkConnectivityUseCase: networkConnectivityGraphSet
                .networkConnectivityUseCaseGraph
                .observeNetworkConnectivityUseCase,
            systemThemeUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .observeSystemThemeUseCase,
            checkAppUpdateUseCase: appUpdateGraphSet.appUpdateUseCaseGraph.checkAppUpdateUseCase
        )
        PresentationDependencyPreparation.prepareLogin(
            &dependencies,
            signInUseCase: authenticationGraphSet.authenticationUseCaseGraph.signInUseCase
        )
        PresentationDependencyPreparation.prepareMain(
            &dependencies,
            observeUnreadPushCountUseCase: pushNotificationGraphSet
                .pushNotificationUseCaseGraph
                .observeUnreadPushCountUseCase
        )
    }

    func prepareTodoDependencies(_ dependencies: inout DependencyValues) {
        TodoDependencyPreparation.prepareDetail(
            &dependencies,
            fetchTodoByIdUseCase: todoGraphSet.todoUseCaseGraph.fetchTodoByIdUseCase,
            fetchReferenceItemsUseCase: todoGraphSet.todoUseCaseGraph.fetchReferenceItemsUseCase
        )
        TodoDependencyPreparation.prepareEditor(
            &dependencies,
            fetchTodoCategoryPreferencesUseCase: todoGraphSet
                .todoCategoryUseCaseGraph
                .fetchTodoCategoryPreferencesUseCase,
            fetchReferenceItemsUseCase: todoGraphSet.todoUseCaseGraph.fetchReferenceItemsUseCase,
            upsertTodoUseCase: todoGraphSet.todoUseCaseGraph.upsertTodoUseCase
        )
        TodoDependencyPreparation.prepareListQuery(
            &dependencies,
            fetchTodosUseCase: todoGraphSet.todoUseCaseGraph.fetchTodosUseCase,
            fetchTodoByIdUseCase: todoGraphSet.todoUseCaseGraph.fetchTodoByIdUseCase,
            fetchReferenceItemsUseCase: todoGraphSet.todoUseCaseGraph.fetchReferenceItemsUseCase,
            fetchTodoCategoryPreferencesUseCase: todoGraphSet
                .todoCategoryUseCaseGraph
                .fetchTodoCategoryPreferencesUseCase
        )
        TodoDependencyPreparation.prepareListMutation(
            &dependencies,
            upsertTodoUseCase: todoGraphSet.todoUseCaseGraph.upsertTodoUseCase,
            deleteTodoUseCase: todoGraphSet.todoUseCaseGraph.deleteTodoUseCase,
            undoDeleteTodoUseCase: todoGraphSet.todoUseCaseGraph.undoDeleteTodoUseCase,
            trackAnalyticsEventUseCase: analyticsGraphSet
                .analyticsUseCaseGraph
                .trackAnalyticsEventUseCase
        )
    }

    func prepareHomeDependencies(_ dependencies: inout DependencyValues) {
        HomePresentationDependencyPreparation.prepareTodoCategory(
            &dependencies,
            updateTodoCategoryPreferencesUseCase: todoGraphSet
                .todoCategoryUseCaseGraph
                .updateTodoCategoryPreferencesUseCase,
            todoMutationEventBus: todoGraphSet.todoMutationEventBusGraph.todoMutationEventBus
        )
        HomePresentationDependencyPreparation.prepareTodo(
            &dependencies,
            fetchTodosUseCase: todoGraphSet.todoUseCaseGraph.fetchTodosUseCase,
            networkConnectivityUseCase: networkConnectivityGraphSet
                .networkConnectivityUseCaseGraph
                .observeNetworkConnectivityUseCase
        )
        HomePresentationDependencyPreparation.prepareSearch(
            &dependencies,
            fetchRecentSearchQueriesUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .fetchRecentSearchQueriesUseCase,
            fetchTodosUseCase: todoGraphSet.todoUseCaseGraph.fetchTodosUseCase,
            updateRecentSearchQueriesUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .updateRecentSearchQueriesUseCase
        )
    }

    func prepareTodayDependencies(_ dependencies: inout DependencyValues) {
        TodayPresentationDependencyPreparation.prepare(
            &dependencies,
            fetchDisplayOptionsUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .fetchTodayDisplayOptionsUseCase,
            fetchTodosUseCase: todoGraphSet.todoUseCaseGraph.fetchTodosUseCase,
            updateDisplayOptionsUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .updateTodayDisplayOptionsUseCase
        )
    }

    func prepareNotificationDependencies(_ dependencies: inout DependencyValues) {
        NotificationDependencyPreparation.prepareQuery(
            &dependencies,
            fetchQueryUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .fetchPushNotificationQueryUseCase,
            updateQueryUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .updatePushNotificationQueryUseCase
        )
        NotificationDependencyPreparation.prepareList(
            &dependencies,
            fetchNotificationsUseCase: pushNotificationGraphSet
                .pushNotificationUseCaseGraph
                .fetchPushNotificationsUseCase,
            deleteNotificationUseCase: pushNotificationGraphSet
                .pushNotificationUseCaseGraph
                .deletePushNotificationUseCase,
            undoDeleteNotificationUseCase: pushNotificationGraphSet
                .pushNotificationUseCaseGraph
                .undoDeletePushNotificationUseCase
        )
        NotificationDependencyPreparation.prepareReadState(
            &dependencies,
            toggleNotificationReadUseCase: pushNotificationGraphSet
                .pushNotificationUseCaseGraph
                .togglePushNotificationReadUseCase
        )
    }

    func prepareProfileDependencies(_ dependencies: inout DependencyValues) {
        ProfilePresentationDependencyPreparation.prepareUser(
            &dependencies,
            fetchUserDataUseCase: userProfileGraphSet.userDataUseCaseGraph.fetchUserDataUseCase,
            fetchProfileImageDataUseCase: userProfileGraphSet
                .profileImageDataUseCaseGraph
                .fetchProfileImageDataUseCase,
            upsertStatusMessageUseCase: userProfileGraphSet
                .userDataUseCaseGraph
                .upsertStatusMessageUseCase
        )
        ProfilePresentationDependencyPreparation.prepareActivity(
            &dependencies,
            fetchTodosUseCase: todoGraphSet.todoUseCaseGraph.fetchTodosUseCase,
            networkConnectivityUseCase: networkConnectivityGraphSet
                .networkConnectivityUseCaseGraph
                .observeNetworkConnectivityUseCase,
            fetchHeatmapActivityTypesUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .fetchHeatmapActivityTypesUseCase,
            updateHeatmapActivityTypesUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .updateHeatmapActivityTypesUseCase
        )
        ProfilePresentationDependencyPreparation.prepareSettingsSession(
            &dependencies,
            deleteAuthUseCase: authenticationGraphSet.authenticationUseCaseGraph.deleteAuthUseCase,
            signOutUseCase: authenticationGraphSet.authenticationUseCaseGraph.signOutUseCase,
            networkConnectivityUseCase: networkConnectivityGraphSet
                .networkConnectivityUseCaseGraph
                .observeNetworkConnectivityUseCase
        )
        ProfilePresentationDependencyPreparation.prepareSettingsAppearance(
            &dependencies,
            systemThemeUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .observeSystemThemeUseCase,
            updateSystemThemeUseCase: userPreferencesGraphSet
                .userPreferencesUseCaseGraph
                .updateSystemThemeUseCase
        )
        ProfilePresentationDependencyPreparation.prepareSettingsStorage(
            &dependencies,
            fetchWebPageImageDirSizeUseCase: webPageGraphSet
                .webPageImageUseCaseGraph
                .fetchWebPageImageDirSizeUseCase,
            clearWebPageImageDirectoryUseCase: webPageGraphSet
                .webPageImageUseCaseGraph
                .clearWebPageImageDirectoryUseCase
        )
        ProfilePresentationDependencyPreparation.prepareAccount(
            &dependencies,
            fetchAuthProvidersUseCase: authenticationGraphSet
                .authProviderUseCaseGraph
                .fetchAuthProvidersUseCase,
            linkAuthProviderUseCase: authenticationGraphSet
                .authProviderUseCaseGraph
                .linkAuthProviderUseCase,
            unlinkAuthProviderUseCase: authenticationGraphSet
                .authProviderUseCaseGraph
                .unlinkAuthProviderUseCase
        )
        ProfilePresentationDependencyPreparation.preparePushSettings(
            &dependencies,
            fetchPushSettingsUseCase: pushNotificationGraphSet
                .pushNotificationUseCaseGraph
                .fetchPushSettingsUseCase,
            updatePushSettingsUseCase: pushNotificationGraphSet
                .pushNotificationUseCaseGraph
                .updatePushSettingsUseCase
        )
    }
}
