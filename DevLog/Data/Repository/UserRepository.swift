//
//  UserRepository.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation

protocol UserRepository {
    func upsertUser(user: AuthUser, fcmToken: String, provider: AuthProvider?, githubAccessToken: String?) async throws
    func fetchPushSettings(userId: String) async throws -> PushNotificationSettings
    func updatePushEnabled(_ userId: String, enabled: Bool) async throws
    func updatePushTime(_ userId: String, hour: Int, minute: Int) async throws
    func updateAppTheme(_ userId: String, theme: SystemTheme) async throws
    func updateFCMToken(_ userId: String, fcmToken: String) async throws
}
