//
//  SystemTheme.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

enum SystemTheme: String, Identifiable {
    case automatic
    case light
    case dark
    
    var id: String {
        rawValue
    }
    
    var localizedName: String {
        switch self {
        case .automatic:
            return NSLocalizedString("자동", comment: "automatic")
        case .light:
            return NSLocalizedString("라이트 모드", comment: "light")
        case .dark:
            return NSLocalizedString("다크 모드", comment: "dark")
        }
    }
    
    var colorScheme: ColorScheme? {
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
