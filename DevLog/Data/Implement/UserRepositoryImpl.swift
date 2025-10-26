//
//  UserRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 10/12/25.
//

import Foundation
import FirebaseAuth

final class UserRepositoryImpl: UserRepository {
    private let userService: UserService
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    func upsertUser(user: User, fcmToken: String, provider: AuthProviderID?, githubAccessToken: String?) async throws {
        try await userService.upsertUser(
            user: user,
            fcmToken: fcmToken,
            provider: provider?.rawValue,
            accessToken: githubAccessToken
        )
    }

    func fetchPushNotificationSettings(userId: String) async throws -> PushNotificationSettings {
        async let pushNotificationEnabled = userService.fetchPushNotificationEnabled(userId)
        async let pushNotificationTime = userService.fetchPushNotificationTime(userId)
        
        let (isEnabled, timeComponents) = try await (pushNotificationEnabled, pushNotificationTime)
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([], from: Date())
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        guard let date = calendar.date(from: dateComponents) else {
            throw NSError(
                domain: "UserRepositoryImpl",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid time components"]
            )
        }
        return PushNotificationSettings(allow: isEnabled, time: date)
    }
    
    func updatePushNotificationEnabled(_ userId: String, enabled: Bool) async throws {
        try await userService.updatePushNotificationEnabled(userId, enabled: enabled)
    }
    
    func updatePushNotificationTime(_ userId: String, time: Date) async throws {
        try await userService.updatePushNotificationTime(userId, time: time)
    }
    
    func updateAppTheme(_ userId: String, theme: SystemTheme) async throws {
        try await userService.updateAppTheme(userId, theme: theme.rawValue)
    }
    
    func updateFCMToken(_ userId: String, fcmToken: String) async throws {
        try await userService.updateFCMToken(userId, fcmToken: fcmToken)
    }
}
