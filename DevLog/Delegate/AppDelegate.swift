//
//  AppDelegate.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import Combine
import UIKit
import Firebase
import FirebaseMessaging
import GoogleSignIn
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        // Firebase Messaging 설정
        Messaging.messaging().delegate = self
        
        // 앱이 완전 종료되어도, 알림을 통해 앱이 시작된 경우 처리
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            NotificationCenter.default.post(name: .pushTapped, object: nil, userInfo: remoteNotification)
        }
        
        return true
    }
    
    // APNs 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        Messaging.messaging().apnsToken = deviceToken
    }

    // APNs 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register APNs Token: \(error)")
    }
    
    // FCMToken 갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("FCM token: \(fcmToken)")
            NotificationCenter.default.post(name: .fcmToken, object: nil, userInfo: ["fcmToken": fcmToken])
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 포그라운드에 있을 때 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Foreground notification: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 클릭 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Tapped notification: \(response.notification.request.content.userInfo)")
        // userInfo["todoId"]로 이동할 Todo 식별
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: .pushTapped, object: nil, userInfo: userInfo)
        completionHandler()
    }
    
    
}

extension Notification.Name {
    static let fcmToken = Notification.Name("fcmToken")
    static let pushTapped = Notification.Name("pushTapped")
}
