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
        guard let uid = authRepository.currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
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
        guard let uid = authRepository.currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        try await userRepository.updatePushNotificationEnabled(uid, enabled: enabled)
    }
    
    func updateTime(_ date: Date) async throws {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
              let minute = components.minute else { return }
        guard let uid = authRepository.currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        try await userRepository.updatePushNotificationTime(uid, time: date)
    }
}

final class UpdateAppTheme {
    private let userRepository: UserRepository
    private let authRepository: AuthRepository
    
    init(userRepository: UserRepository, authRepository: AuthRepository) {
        self.userRepository = userRepository
        self.authRepository = authRepository
    }
    
    func update(_ theme: SystemTheme) async throws {
        guard let uid = authRepository.currentUser?.uid else { throw URLError(.userAuthenticationRequired) }
        try await userRepository.updateAppTheme(uid, theme: theme)
    }
}
