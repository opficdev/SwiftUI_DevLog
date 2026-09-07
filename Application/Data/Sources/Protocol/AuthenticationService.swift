//
//  AuthenticationService.swift
//  Data
//
//  Created by 최윤진 on 11/3/25.
//

import Foundation

public protocol AuthenticationService {
    func signIn() async throws -> AuthDataResponse?
    func clearLocalSession()
    func deleteAuth(_ uid: String) async throws
    func link(uid: String) async throws -> Bool
    func unlink(_ uid: String) async throws
}

public protocol AppleAuthenticationService: AuthenticationService { }

public protocol GithubAuthenticationService: AuthenticationService { }

public protocol GoogleAuthenticationService: AuthenticationService { }
