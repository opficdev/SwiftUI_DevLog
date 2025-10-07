//
//  Array.swift
//  DevLog
//
//  Created by opfic on 6/19/25.
//

import Foundation

//  AppStorage에서 배열을 저장할 수 있도록 해주는 Extension
//  @retroactive를 사용하여 후에 애플이 이 Extension의 기능을 제공했을 때 중복되었을 때 에러 방지 및 컴파일러 경고 제거
extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
