//
//  AppDelegate.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import UIKit
import Core
import Data
import Infra
import Widget

class AppDelegate: UIResponder, UIApplicationDelegate {
    private let logger = Logger(category: "AppDelegate")

    // Google 로그인 URL 콜백 처리
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GoogleSignInURLHandler.handle(url)
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let lifecycleGraphSet = AppGraph.shared.lifecycleGraphSet
        _ = lifecycleGraphSet.fcmTokenSyncHandlerGraph.fcmTokenSyncHandler
        _ = lifecycleGraphSet.userTimeZoneSyncHandlerGraph.userTimeZoneSyncHandler
        _ = lifecycleGraphSet.widgetSyncEventHandlerGraph.widgetSyncEventHandler
        _ = lifecycleGraphSet.widgetSessionSyncHandlerGraph.widgetSessionSyncHandler
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteNotificationRegistrationRequest),
            name: .didRequestRemoteNotificationRegistration,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(requestUserTimeZoneSync),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(requestAPNsRegistration),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                self.logger.error("Notification authorization error", error: error)
            } else {
                self.logger.info("Notification permission granted: \(granted)")
                NotificationCenter.default.post(name: .didRequestFCMTokenSync, object: nil)
            }
        }

        // Firebase Messaging 설정
        AppGraph.shared.infraGraphSet.pushMessagingServiceGraph.pushMessagingService.setDelegate(self)

        // 앱이 완전 종료되어도, 알림을 통해 앱이 시작된 경우 처리
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            let handler = lifecycleGraphSet.pushNotificationOpenHandlerGraph.pushNotificationOpenHandler
            Task { @MainActor in
                handler.handlePushOpen(userInfo: remoteNotification)
            }
        }

        return true
    }

    @objc private func handleRemoteNotificationRegistrationRequest() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    @objc private func requestAPNsRegistration() {
        NotificationCenter.default.post(name: .didRequestAPNsRegistration, object: nil)
    }

    @objc private func requestUserTimeZoneSync() {
        NotificationCenter.default.post(name: .didRequestUserTimeZoneSync, object: nil)
    }

    // APNs 등록 성공
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        logger.info("APNs token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        NotificationCenter.default.post(
            name: .didReceiveAPNSToken,
            object: nil,
            userInfo: ["deviceToken": deviceToken]
        )
    }

    // APNs 등록 실패
    func application(
        _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("Failed to register APNs token", error: error)
    }

}

extension AppDelegate: PushMessagingServiceDelegate {
    func pushMessagingService(_ service: PushMessagingService, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            logger.info("FCM token: \(fcmToken)")
            NotificationCenter.default.post(
                name: .didRefreshFCMToken,
                object: nil,
                userInfo: ["fcmToken": fcmToken]
            )
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 포그라운드에 있을 때 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logger.info("Foreground notification: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 클릭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.info("Tapped notification: \(response.notification.request.content.userInfo)")
        let userInfo = response.notification.request.content.userInfo
        let handler = AppGraph.shared
            .lifecycleGraphSet
            .pushNotificationOpenHandlerGraph
            .pushNotificationOpenHandler
        Task { @MainActor in
            handler.handlePushOpen(userInfo: userInfo)
        }
        completionHandler()
    }
}
