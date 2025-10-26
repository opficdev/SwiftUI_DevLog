//
//  Auth+.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation
import Combine

final class AuthState {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    var publisher: AnyPublisher<AuthUser?, Never> { authRepository.publisher }
}

final class DeleteAuth {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    func delete() async throws { try await authRepository.deleteAuth() }
}
