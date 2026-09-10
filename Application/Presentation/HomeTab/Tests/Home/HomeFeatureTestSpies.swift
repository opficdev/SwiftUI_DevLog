//
//  HomeFeatureTestSpies.swift
//  HomeTabTests
//
//  Created by opfic on 7/2/26.
//

import Combine
import Core
import Domain

@MainActor
func waitUntil(
    timeout: Duration = .seconds(1),
    pollInterval: Duration = .milliseconds(20),
    _ condition: @escaping () -> Bool
) async {
    let continuousClock = ContinuousClock()
    let deadline = continuousClock.now + timeout

    while !condition() && continuousClock.now < deadline {
        try? await Task.sleep(for: pollInterval)
    }
}

final class FetchTodoCategoryPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCase {
    private(set) var executeCount = 0
    var todoCategoryPreferences: [TodoCategoryPreference] = []

    func execute() async throws -> [TodoCategoryPreference] {
        executeCount += 1
        return todoCategoryPreferences
    }
}

final class UpdateTodoCategoryPreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCase {
    private(set) var updates: [[TodoCategoryPreference]] = []

    func execute(_ preferences: [TodoCategoryPreference]) async throws {
        updates.append(preferences)
    }
}

final class ObserveNetworkConnectivityUseCaseSpy: ObserveNetworkConnectivityUseCase {
    let currentValueSubject = CurrentValueSubject<Bool, Never>(true)

    func observe() -> AnyPublisher<Bool, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }
}
