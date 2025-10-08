//
//  SignInWithApple.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation

final class SignInWithApple {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func signIn() async throws -> (AuthUser, String) { try await repo.signInWithApple() }
}

final class SignInWithGithub {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func signIn() async throws -> (AuthUser, String, String) { try await repo.signInWithGithub() }
}

final class SignInWithGoogle {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func signIn() async throws -> (AuthUser, String) { try await repo.signInWithGoogle() }
}

final class SignOut {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func signOut() async throws { try await repo.signOut() }
}
