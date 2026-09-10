//
//  HomeFeature+Dependencies.swift
//  HomeTab
//
//  Created by opfic on 6/14/26.
//

import PresentationShared
import Domain

extension DependencyValues {
    var homeUpdateTodoCategoryPreferencesUseCase: UpdateTodoCategoryPreferencesUseCase {
        get { self[HomeUpdatePreferencesUseCaseKey.self] }
        set { self[HomeUpdatePreferencesUseCaseKey.self] = newValue }
    }

    var homeNetworkConnectivityUseCase: ObserveNetworkConnectivityUseCase {
        get { self[HomeNetworkConnectivityUseCaseKey.self] }
        set { self[HomeNetworkConnectivityUseCaseKey.self] = newValue }
    }
}

private enum HomeUpdatePreferencesUseCaseKey: DependencyKey {
    static var liveValue: UpdateTodoCategoryPreferencesUseCase {
        preconditionFailure("UpdateTodoCategoryPreferencesUseCase must be provided.")
    }

    static var testValue: UpdateTodoCategoryPreferencesUseCase {
        liveValue
    }
}

private enum HomeNetworkConnectivityUseCaseKey: DependencyKey {
    static var liveValue: ObserveNetworkConnectivityUseCase {
        preconditionFailure("ObserveNetworkConnectivityUseCase must be provided.")
    }

    static var testValue: ObserveNetworkConnectivityUseCase {
        liveValue
    }
}
