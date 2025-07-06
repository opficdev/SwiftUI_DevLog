//
//  String.swift
//  DevLog
//
//  Created by opfic on 5/19/25.
//

import Foundation

// UpperCamelCase → snake_case 변환
extension String {
    var toSnakeCase: String {
        unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                return ($0.isEmpty ? "" : $0 + "_") + String($1).lowercased()
            }
            return $0 + String($1)
        }
    }
    
    var upperCamelCase: String {
        guard let first = self.first else { return "" }
        return first.uppercased() + self.dropFirst()
    }
}
