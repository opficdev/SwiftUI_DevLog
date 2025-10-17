//
//  UserRepository.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation
import FirebaseAuth

protocol UserRepository {
    func upsertUser(user: AuthUser, fcmToken: String, provider: AuthProviderID?, githubAccessToken: String?) async throws
    func fetchPushNotificationSettings(userId: String) async throws -> PushNotificationSettings
    func updatePushNotificationEnabled(_ userId: String, enabled: Bool) async throws
    func updatePushNotificationTime(_ userId: String, time: Date) async throws
    func updateAppTheme(_ userId: String, theme: SystemTheme) async throws
    func updateFCMToken(_ userId: String, fcmToken: String) async throws
}
