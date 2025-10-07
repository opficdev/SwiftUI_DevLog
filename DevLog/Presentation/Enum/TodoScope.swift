//
//  TodoScope.swift
//  DevLog
//
//  Created by opfic on 6/12/25.
//

import Foundation

enum TodoScope: String, CaseIterable {
    case title, content
    
    var localizedName: String {
        let key: String.LocalizationValue
        switch self {
        case .title:
            key = "TodoScope.title"
        case .content:
            key = "TodoScope.content"
        }
        return String(localized: key)
    }
}
