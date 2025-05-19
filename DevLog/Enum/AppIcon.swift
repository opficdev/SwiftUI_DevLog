//
//  AppIcon.swift
//  DevLog
//
//  Created by opfic on 5/19/25.
//

import Foundation

enum AppIcon: String {
    case limeGreen, nightSky, orange, pink, primary, rainbow, sky, sun
 
    init?(iconName: String) {
        // UpperCamelCase → lowerCamelCase 변환
       let lower = iconName.prefix(1).lowercased() + iconName.dropFirst()
       self.init(rawValue: lower)
   }

    // Localizable 키 (snake_case)
    var localizationKey: String {
        let snake = rawValue.replacingOccurrences(of: "([A-Z])", with: "_$1", options: .regularExpression).lowercased()
        return snake.hasPrefix("_") ? String(snake.dropFirst()) : snake
    }

    var localizedName: String {
        NSLocalizedString(localizationKey, comment: "")
    }
}
