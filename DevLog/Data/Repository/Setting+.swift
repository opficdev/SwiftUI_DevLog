//
//  Setting+.swift
//  DevLog
//
//  Created by 최윤진 on 10/8/25.
//

import Foundation

final class FetchPushNotificationSettings {
    private let authRepository: AuthRepository
    private let userRepository: UserRepository
    
    init(authRepository: AuthRepository, userRepository: UserRepository) {
        self.authRepository = authRepository
        self.userRepository = userRepository
    }
    
    func fetch() async throws -> PushNotificationSettings {
        guard let uid = await authRepository.publisher
            .compactMap({ $0?.uid })
            .prefix(1)
            .values
            .first(where: { _ in true }) else {
                throw URLError(.userAuthenticationRequired)
            }
        return try await userRepository.fetchPushNotificationSettings(userId: uid)
    }
}

final class UpdatePushNotificationSettings {
    private let authRepository: AuthRepository
    private let userRepository: UserRepository
    
    init(authRepository: AuthRepository, userRepository: UserRepository) {
        self.authRepository = authRepository
        self.userRepository = userRepository
    }
    
    func updateEnabled(_ enabled: Bool) async throws {
        guard let uid = await authRepository.publisher
            .compactMap({ $0?.uid })
            .prefix(1)
            .values
            .first(where: { _ in true }) else {
            throw URLError(.userAuthenticationRequired)
        }
        try await userRepository.updatePushNotificationEnabled(uid, enabled: enabled)
    }
    
    func updateTime(_ date: Date) async throws {
        guard let uid = await authRepository.publisher
            .compactMap({ $0?.uid })
            .prefix(1)
            .values
            .first(where: { _ in true }) else {
            throw URLError(.userAuthenticationRequired)
        }
        try await userRepository.updatePushNotificationTime(uid, time: date)
    }
}

final class UpdateAppTheme {
    private let authRepository: AuthRepository
    private let userRepository: UserRepository

    init(authRepository: AuthRepository, userRepository: UserRepository) {
        self.authRepository = authRepository
        self.userRepository = userRepository
    }
    
    func update(_ theme: SystemTheme) async throws {
        guard let uid = await authRepository.publisher
            .compactMap({ $0?.uid })
            .prefix(1)
            .values
            .first(where: { _ in true }) else {
            throw URLError(.userAuthenticationRequired)
        }
        try await userRepository.updateAppTheme(uid, theme: theme)
    }
}
