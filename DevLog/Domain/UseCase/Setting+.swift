//
//  Setting+.swift
//  DevLog
//
//  Created by 최윤진 on 10/8/25.
//

import Foundation

final class FetchPushNotificationSettings {
    private let repo: UserRepository
    private let auth: AuthRepository
    
    init(repo: UserRepository, auth: AuthRepository) {
        self.repo = repo
        self.auth = auth
    }
    
    func fetch() async throws -> PushNotificationSettings {
        guard let uid = auth.currentUser?.id else { throw URLError(.userAuthenticationRequired) }
        return try await repo.fetchPushSettings(userId: uid)
    }
}

final class UpdatePushNotificationSettings {
    private let repo: UserRepository
    private let auth: AuthRepository
    
    init(repo: UserRepository, auth: AuthRepository) {
        self.repo = repo
        self.auth = auth
    }
    
    func updateEnabled(_ enabled: Bool) async throws {
        guard let uid = auth.currentUser?.id else { throw URLError(.userAuthenticationRequired) }
        try await repo.updatePushEnabled(uid, enabled: enabled)
    }
    
    func updateTime(_ date: Date) async throws {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
              let minute = components.minute else { return }
        guard let uid = auth.currentUser?.id else { throw URLError(.userAuthenticationRequired) }
        try await repo.updatePushTime(uid, hour: hour, minute: minute)
    }
}

final class UpdateAppTheme {
    private let repo: UserRepository
    private let auth: AuthRepository
    
    init(repo: UserRepository, auth: AuthRepository) {
        self.repo = repo
        self.auth = auth
    }
    
    func update(_ theme: SystemTheme) async throws {
        guard let uid = auth.currentUser?.id else { throw URLError(.userAuthenticationRequired) }
        try await repo.updateAppTheme(uid, theme: theme)
    }
}
