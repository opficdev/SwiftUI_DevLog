//
//  AnalyticsRepositoryImpl.swift
//  Data
//
//  Created by opfic on 5/27/26.
//

import Domain

final class AnalyticsRepositoryImpl: AnalyticsRepository {
    private let analyticsService: AnalyticsService

    init(analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
    }

    func track(_ event: AnalyticsEvent) {
        switch event {
        case .screenView(let name):
            analyticsService.trackScreenView(name)
        case .todoCreate:
            analyticsService.trackTodoCreate()
        case .todoComplete:
            analyticsService.trackTodoComplete()
        case .pushOpen:
            analyticsService.trackPushOpen()
        }
    }
}
