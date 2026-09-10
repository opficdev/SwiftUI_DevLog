//
//  PushNotificationQuery+Presentation.swift
//  NotificationTab
//
//  Created by opfic on 6/17/26.
//

import Core
import Foundation
import PresentationShared

public extension PushNotificationQuery.SortOrder {
    var title: String {
        switch self {
        case .latest:
            return String(localized: "push_sort_latest", bundle: PresentationResources.bundle)
        case .oldest:
            return String(localized: "push_sort_oldest", bundle: PresentationResources.bundle)
        }
    }
}

public extension PushNotificationQuery.TimeFilter {
    var title: String {
        switch self {
        case .none:
            return String(localized: "push_timefilter_all", bundle: PresentationResources.bundle)
        case .hours(let value):
            return String.localizedStringWithFormat(
                String(localized: "push_timefilter_hours_format", bundle: PresentationResources.bundle),
                Int64(value)
            )
        case .days(let value):
            return String.localizedStringWithFormat(
                String(localized: "push_timefilter_days_format", bundle: PresentationResources.bundle),
                Int64(value)
            )
        }
    }

    static var availableOptions: [PushNotificationQuery.TimeFilter] { [
        .none,
        .hours(1),
        .hours(6),
        .hours(12),
        .days(1),
        .days(7),
        .days(30)
    ] }
}
