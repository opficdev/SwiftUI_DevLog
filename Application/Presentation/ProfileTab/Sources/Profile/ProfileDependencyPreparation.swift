//
//  ProfileDependencyPreparation.swift
//  ProfileTab
//
//  Created by opfic on 9/7/26.
//

import Domain
import PresentationShared

public enum ProfileDependencyPreparation {
    public static func prepareUser(
        _ dependencies: inout DependencyValues,
        fetchUserDataUseCase: FetchUserDataUseCase,
        fetchProfileImageDataUseCase: FetchProfileImageDataUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    ) {
        dependencies.profileFetchUserDataUseCase = fetchUserDataUseCase
        dependencies.profileFetchImageDataUseCase = fetchProfileImageDataUseCase
        dependencies.profileUpsertStatusMessageUseCase = upsertStatusMessageUseCase
    }

    public static func prepareActivity(
        _ dependencies: inout DependencyValues,
        fetchTodosUseCase: FetchTodosUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        fetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCase,
        updateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCase
    ) {
        dependencies.profileFetchTodosUseCase = fetchTodosUseCase
        dependencies.profileNetworkConnectivityUseCase = networkConnectivityUseCase
        dependencies.profileFetchHeatmapActivityTypesUseCase = fetchHeatmapActivityTypesUseCase
        dependencies.profileUpdateHeatmapActivityTypesUseCase = updateHeatmapActivityTypesUseCase
    }

    public static func prepareSettingsSession(
        _ dependencies: inout DependencyValues,
        deleteAuthUseCase: DeleteAuthUseCase,
        signOutUseCase: SignOutUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    ) {
        dependencies.deleteAuthUseCase = deleteAuthUseCase
        dependencies.signOutUseCase = signOutUseCase
        dependencies.profileNetworkConnectivityUseCase = networkConnectivityUseCase
    }

    public static func prepareSettingsAppearance(
        _ dependencies: inout DependencyValues,
        systemThemeUseCase: ObserveSystemThemeUseCase,
        updateSystemThemeUseCase: UpdateSystemThemeUseCase
    ) {
        dependencies.profileSystemThemeUseCase = systemThemeUseCase
        dependencies.updateSystemThemeUseCase = updateSystemThemeUseCase
    }

    public static func prepareSettingsStorage(
        _ dependencies: inout DependencyValues,
        fetchWebPageImageDirSizeUseCase: FetchWebPageImageDirSizeUseCase,
        clearWebPageImageDirectoryUseCase: ClearWebPageImageDirectoryUseCase
    ) {
        dependencies.fetchWebPageImageDirSizeUseCase = fetchWebPageImageDirSizeUseCase
        dependencies.clearWebPageImageDirectoryUseCase = clearWebPageImageDirectoryUseCase
    }

    public static func prepareAccount(
        _ dependencies: inout DependencyValues,
        fetchAuthProvidersUseCase: FetchAuthProvidersUseCase,
        linkAuthProviderUseCase: LinkAuthProviderUseCase,
        unlinkAuthProviderUseCase: UnlinkAuthProviderUseCase
    ) {
        dependencies.fetchAuthProvidersUseCase = fetchAuthProvidersUseCase
        dependencies.linkAuthProviderUseCase = linkAuthProviderUseCase
        dependencies.unlinkAuthProviderUseCase = unlinkAuthProviderUseCase
    }

    public static func preparePushSettings(
        _ dependencies: inout DependencyValues,
        fetchPushSettingsUseCase: FetchPushSettingsUseCase,
        updatePushSettingsUseCase: UpdatePushSettingsUseCase
    ) {
        dependencies.fetchPushSettingsUseCase = fetchPushSettingsUseCase
        dependencies.updatePushSettingsUseCase = updatePushSettingsUseCase
    }
}
