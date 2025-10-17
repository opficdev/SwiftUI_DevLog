//
//  AuthRepository.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation
import Combine
import FirebaseAuth

protocol AuthRepository {
    var authStatePublisher: AnyPublisher<AuthUser?, Never> { get }
    var currentUser: AuthUser? { get }
    
    func signInWithApple() async throws -> (AuthUser, String /* fcmToken */)
    func signInWithGoogle() async throws -> (AuthUser, String)
    func signInWithGithub() async throws -> (AuthUser, String /* fcmToken */, String /* githubAccessToken */)
    
    func signOut() async throws
    func deleteAuth() async throws
    
    func link(provider: AuthProviderID) async throws
    func unlink(provider: AuthProviderID) async throws
}
