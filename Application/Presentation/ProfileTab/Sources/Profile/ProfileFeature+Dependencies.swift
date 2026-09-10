//
//  ProfileFeature+Dependencies.swift
//  ProfileTab
//
//  Created by opfic on 6/15/26.
//

import PresentationShared
import Domain

extension DependencyValues {
    var profileFetchUserDataUseCase: FetchUserDataUseCase {
        get { self[ProfileFetchUserDataKey.self] }
        set { self[ProfileFetchUserDataKey.self] = newValue }
    }

    var profileFetchImageDataUseCase: FetchProfileImageDataUseCase {
        get { self[ProfileFetchImageDataKey.self] }
        set { self[ProfileFetchImageDataKey.self] = newValue }
    }

    var profileFetchTodosUseCase: FetchTodosUseCase {
        get { self[ProfileFetchTodosKey.self] }
        set { self[ProfileFetchTodosKey.self] = newValue }
    }

    var profileTodoMutationEventBus: TodoMutationEventBus {
        get { self[ProfileTodoMutationEventBusKey.self] }
        set { self[ProfileTodoMutationEventBusKey.self] = newValue }
    }

    var profileUpsertStatusMessageUseCase: UpsertStatusMessageUseCase {
        get { self[ProfileUpsertStatusMessageKey.self] }
        set { self[ProfileUpsertStatusMessageKey.self] = newValue }
    }

    var profileFetchHeatmapActivityTypesUseCase: FetchHeatmapActivityTypesUseCase {
        get { self[ProfileFetchHeatmapTypesKey.self] }
        set { self[ProfileFetchHeatmapTypesKey.self] = newValue }
    }

    var profileUpdateHeatmapActivityTypesUseCase: UpdateHeatmapActivityTypesUseCase {
        get { self[ProfileUpdateHeatmapTypesKey.self] }
        set { self[ProfileUpdateHeatmapTypesKey.self] = newValue }
    }
}

private enum ProfileFetchUserDataKey: DependencyKey {
    static var liveValue: FetchUserDataUseCase {
        preconditionFailure("FetchUserDataUseCase must be provided.")
    }

    static var testValue: FetchUserDataUseCase {
        liveValue
    }
}

private enum ProfileFetchImageDataKey: DependencyKey {
    static var liveValue: FetchProfileImageDataUseCase {
        preconditionFailure("FetchProfileImageDataUseCase must be provided.")
    }

    static var testValue: FetchProfileImageDataUseCase {
        liveValue
    }
}

private enum ProfileFetchTodosKey: DependencyKey {
    static var liveValue: FetchTodosUseCase {
        preconditionFailure("FetchTodosUseCase must be provided.")
    }

    static var testValue: FetchTodosUseCase {
        liveValue
    }
}

private enum ProfileTodoMutationEventBusKey: DependencyKey {
    static var liveValue: TodoMutationEventBus {
        preconditionFailure("TodoMutationEventBus must be provided.")
    }
}

private enum ProfileUpsertStatusMessageKey: DependencyKey {
    static var liveValue: UpsertStatusMessageUseCase {
        preconditionFailure("UpsertStatusMessageUseCase must be provided.")
    }

    static var testValue: UpsertStatusMessageUseCase {
        liveValue
    }
}

private enum ProfileFetchHeatmapTypesKey: DependencyKey {
    static var liveValue: FetchHeatmapActivityTypesUseCase {
        preconditionFailure("FetchHeatmapActivityTypesUseCase must be provided.")
    }

    static var testValue: FetchHeatmapActivityTypesUseCase {
        liveValue
    }
}

private enum ProfileUpdateHeatmapTypesKey: DependencyKey {
    static var liveValue: UpdateHeatmapActivityTypesUseCase {
        preconditionFailure("UpdateHeatmapActivityTypesUseCase must be provided.")
    }

    static var testValue: UpdateHeatmapActivityTypesUseCase {
        liveValue
    }
}
