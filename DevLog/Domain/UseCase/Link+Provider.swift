//
//  Link+Provider.swift
//  DevLog
//
//  Created by 최윤진 on 10/8/25.
//

import Foundation

final class LinkProvider {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func link(_ provider: AuthProvider) async throws { try await repo.link(provider: provider) }
}

final class UnlinkProvider {
    private let repo: AuthRepository
    init(repo: AuthRepository) { self.repo = repo }
    func unlink(_ provider: AuthProvider) async throws { try await repo.unlink(provider: provider) }
}
