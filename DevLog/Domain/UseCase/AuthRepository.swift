//
//  AuthRepository.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation
import Combine

protocol AuthRepository {
    var publisher: AnyPublisher<AuthUser?, Never> { get }
    func signInWithApple() async throws -> (AuthUser, String)    // fcmToken
    func signInWithGoogle() async throws -> (AuthUser, String)
    func signInWithGithub() async throws -> (AuthUser, String, String)   // fcmToken, githubAccessToken
    func signOut() async throws
    func deleteAuth() async throws
    func link(provider: AuthProvider) async throws
    func unlink(provider: AuthProvider) async throws
}
