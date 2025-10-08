//
//  Link+Provider.swift
//  DevLog
//
//  Created by 최윤진 on 10/8/25.
//

import Foundation

struct LinkProvider {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func link(_ provider: AuthProvider) async throws { try await repo.link(provider: provider) }
}

struct UnlinkProvider {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func unlink(_ provider: AuthProvider) async throws { try await repo.unlink(provider: provider) }
}
