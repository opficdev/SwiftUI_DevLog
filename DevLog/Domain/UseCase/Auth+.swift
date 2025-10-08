//
//  AuthState.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation
import Combine

final class AuthState {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    var publisher: AnyPublisher<AuthUser?, Never> { repo.authStatePublisher }
}

final class DeleteAuth {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func delete() async throws { try await repo.deleteAuth() }
}
