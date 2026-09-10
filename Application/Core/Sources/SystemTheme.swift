//
//  SystemTheme.swift
//  Core
//
//  Created by opfic on 5/6/25.
//

import SwiftUI
import Foundation

public enum SystemTheme: String, Identifiable {
    case automatic
    case light
    case dark
    
    public var id: String {
        rawValue
    }
    
    public var localizedName: String {
        localizedName(in: .main)
    }

    public func localizedName(in bundle: Bundle) -> String {
        switch self {
        case .automatic:
            return String(localized: "system_theme_automatic", bundle: bundle)
        case .light:
            return String(localized: "system_theme_light", bundle: bundle)
        case .dark:
            return String(localized: "system_theme_dark", bundle: bundle)
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .automatic:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
