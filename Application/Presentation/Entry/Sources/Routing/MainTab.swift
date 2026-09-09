//
//  MainTab.swift
//  Entry
//
//  Created by opfic on 4/30/26.
//

import Foundation

public enum MainTab: Hashable, CaseIterable {
    case home
    case today
    case notification
    case profile

    var title: String {
        switch self {
        case .home:
            String(localized: "nav_home")
        case .today:
            String(localized: "nav_today")
        case .notification:
            String(localized: "nav_notifications")
        case .profile:
            String(localized: "nav_profile")
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            "house.fill"
        case .today:
            "sun.max.fill"
        case .notification:
            "bell.fill"
        case .profile:
            "person.crop.circle.fill"
        }
    }
}
