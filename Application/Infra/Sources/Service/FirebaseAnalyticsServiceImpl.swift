//
//  FirebaseAnalyticsServiceImpl.swift
//  Infra
//
//  Created by opfic on 5/27/26.
//

import Data
import FirebaseAnalytics

final class FirebaseAnalyticsServiceImpl: AnalyticsService {
    private enum EventName {
        static let todoCreate = "todo_create"
        static let todoComplete = "todo_complete"
        static let pushOpen = "push_open"
    }

    func trackScreenView(_ name: String) {
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: name
            ]
        )
    }

    func trackTodoCreate() {
        Analytics.logEvent(EventName.todoCreate, parameters: nil)
    }

    func trackTodoComplete() {
        Analytics.logEvent(EventName.todoComplete, parameters: nil)
    }

    func trackPushOpen() {
        Analytics.logEvent(EventName.pushOpen, parameters: nil)
    }
}
