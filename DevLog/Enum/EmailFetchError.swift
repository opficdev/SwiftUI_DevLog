//
//  EmailFetchError.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import Foundation

enum EmailFetchError: Error, Equatable {
    case emailNotFound  //  이메일을 찾을 수 없음
    case emailMismatch  //  이메일 불일치
}
