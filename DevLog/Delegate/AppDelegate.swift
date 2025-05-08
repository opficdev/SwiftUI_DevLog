//
//  AppDelegate.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

    //  gRPC 관련 환경 변수 설정 (GRPC_TRACE 제거)
    setenv("GRPC_VERBOSITY", "ERROR", 1)
    unsetenv("GRPC_TRACE") // GRPC_TRACE 환경 변수 제거

    //  Firebase 디버그 로그 활성화
    //  FirebaseConfiguration.shared.setLoggerLevel(.debug)

        return true
    }
}
