//
//  ProfileAvatarImageData.swift
//  ProfileTab
//
//  Created by opfic on 6/17/26.
//

import Foundation

struct ProfileAvatarImageData: Equatable {
    let id: Int
    let data: Data

    static func == (lhs: ProfileAvatarImageData, rhs: ProfileAvatarImageData) -> Bool {
        lhs.id == rhs.id
    }
}
