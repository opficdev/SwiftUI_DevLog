//
//  AuthUser.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation

struct AuthUser: Equatable {
    let id: String
    let email: String?
    let providers: [String]
    let currentProvider: String?
}
