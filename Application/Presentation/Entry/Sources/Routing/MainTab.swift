//
//  MainTab.swift
//  Entry
//
//  Created by opfic on 4/30/26.
//

import Foundation
import PresentationShared

public enum MainTab: Hashable, CaseIterable {
    case home
    case today
    case notification
    case profile

    var title: String {
        switch self {
        case .home:
            String(localized: "nav_home", bundle: PresentationResources.bundle)
        case .today:
            String(localized: "nav_today", bundle: PresentationResources.bundle)
        case .notification:
            String(localized: "nav_notifications", bundle: PresentationResources.bundle)
        case .profile:
            String(localized: "nav_profile", bundle: PresentationResources.bundle)
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
