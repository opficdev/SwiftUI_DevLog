//
//  TodayViewCoordinator.swift
//  TodayTab
//
//  Created by opfic on 5/10/26.
//

import Foundation
import Domain
import PresentationShared

@MainActor
@Observable
public final class TodayViewCoordinator {
    let store: StoreOf<TodayFeature>
    public let router = NavigationRouter<TodayRoute>()

    public init() {
        @Dependency(\.todayFetchDisplayOptionsUseCase) var fetchDisplayOptionsUseCase
        self.store = Store(
            initialState: TodayFeature.State(
                displayOptions: fetchDisplayOptionsUseCase.execute()
            )
        ) {
            TodayFeature()
        }
    }

    public func fetchData() {
        store.send(.fetchData)
    }
}
