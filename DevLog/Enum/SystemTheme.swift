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
