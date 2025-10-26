//
//  Link+Provider.swift
//  DevLog
//
//  Created by 최윤진 on 10/8/25.
//

import Foundation
import FirebaseAuth

final class LinkProvider {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    func link(_ provider: AuthProviderID) async throws { try await authRepository.link(provider: provider) }
}

final class UnlinkProvider {
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) { self.authRepository = authRepository }
    func unlink(_ provider: AuthProviderID) async throws { try await authRepository.unlink(provider: provider) }
}
