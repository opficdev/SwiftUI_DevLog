//
//  GithubUser.swift
//  DevLog
//
//  Created by opfic on 5/13/25.
//

import Foundation

struct GitHubUser: Codable {
    let login: String
    let name: String?
    let avatarUrl: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case login
        case name
        case avatarUrl = "avatar_url"
        case email
    }
}
