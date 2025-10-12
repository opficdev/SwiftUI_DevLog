//
//  SignInWithApple.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation

final class SignInWithApple {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    func signIn() async throws -> (AuthUser, String) { try await authRepository.signInWithApple() }
}

final class SignInWithGithub {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    func signIn() async throws -> (AuthUser, String, String) { try await authRepository.signInWithGithub() }
}

final class SignInWithGoogle {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    func signIn() async throws -> (AuthUser, String) { try await authRepository.signInWithGoogle() }
}

final class SignOut {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    func signOut() async throws { try await authRepository.signOut() }
}
