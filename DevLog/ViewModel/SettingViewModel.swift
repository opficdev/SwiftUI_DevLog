//
//  SettingViewModel.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import Combine
import SwiftUI
import UIKit
import FirebaseFirestore
import FirebaseMessaging

@MainActor
class SettingViewModel: ObservableObject {
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    private let userSvc: UserService
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    @Published var theme: String = ""
    
    @Published var showAlert: Bool = false
    @Published var alertMsg: String = ""
    
    // AuthInfo
    @Published var currentProvider = ""
    @Published var providers: [String] = []
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    @Published var showNetworkAlert: Bool = false
    
    @Published var pushNotificationEnabled: Bool = true
//    @Published var pushNotificationHour: Int = 9 // 기본값은 오전 9시
    @Published var pushNotificationTime = Date()
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, userSvc: UserService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.userSvc = userSvc
        
        // 현재 로그인된 사용자의 인증 정보를 가져옴
        self.authSvc.$currentProvider
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$currentProvider)
        
        self.authSvc.$providers
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$providers)
        
        // NetworkActivityService.isConnected를 self.isConnected와와 단방향 연결
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
        
        // NetworkActivityService.showNetworkAlert를 self.showNetworkAlert와 단방향 연결
        self.networkSvc.$showNetworkAlert
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$showNetworkAlert)
        
        Task {
            await self.fetchPushNotificationSettings()
        }
        
        self.$pushNotificationEnabled
            .dropFirst() // 초기값은 무시
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.updatePushNotificationEnabled()
                }
            }
            .store(in: &self.cancellables)
        
        self.$pushNotificationTime
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.updatePushNotificationTime()
                }
            }
            .store(in: &self.cancellables)
        
        self.$theme
            .dropFirst() // 초기값은 무시
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.updateAppTheme()
                }
            }
            .store(in: &self.cancellables)
    }
    
    func signOut() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.authSvc.signOut()
            
            let keys = UserDefaults.standard.dictionaryRepresentation().keys
            for key in keys where key != "isFirstLaunch" {
                UserDefaults.standard.removeObject(forKey: key)
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.alertMsg = "로그아웃 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func deleteAuth() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.authSvc.deleteAuth()
            
            let keys = UserDefaults.standard.dictionaryRepresentation().keys
            for key in keys where key != "isFirstLaunch" {
                UserDefaults.standard.removeObject(forKey: key)
            }
        } catch {
            print("Error deleting user: \(error.localizedDescription)")
            self.alertMsg = "회원탈퇴 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func linkWithProvider(provider: String) async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.authSvc.linkWithProvider(provider: provider)

        } catch {
            print("Error linking with provider: \(error.localizedDescription)")
            if let emailError = error as? EmailFetchError, emailError == .emailNotFound {
                alertMsg = "연동하려는 계정의 이메일을 확인할 수 없습니다."
            }
            else if let emailError = error as? EmailFetchError, emailError == .emailMismatch {
                alertMsg = "동일한 이메일을 가진 계정과 연동을 시도해주세요."
            }
            else {
                alertMsg = "알 수 없는 오류가 발생했습니다."
            }
            
            self.showAlert = true
        }
    }
    
    func unlinkFromProvider(provider: String) async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.authSvc.unlinkFromProvider(provider: provider)
            
        } catch {
            print("Error unlinking with provider: \(error.localizedDescription)")
            
            self.showAlert = true
        }
    }

    func fetchPushNotificationSettings() async {
        if !self.isConnected { return }
        
        self.isLoading = true
        defer { self.isLoading = false }
        
        guard let userId = self.authSvc.user?.uid else { return }
        
        async let enabledTask = self.userSvc.fetchAllowPushNotification(userId)
        async let timeTask = self.userSvc.fetchPushNotifcationTime(userId)
        
        do {
            self.pushNotificationEnabled = try await enabledTask
        } catch {
            print("푸시 알람 활성화 여부 불러오기 실패: \(error.localizedDescription)")
            self.alertMsg = "푸시 알람 설정을 불러오는 중 오류가 발생했습니다."
            self.showAlert = true
        }
        
        do {
            let components = try await timeTask
            guard let time = Calendar.current.date(from: components) else { return }
            self.pushNotificationTime = time
        } catch {
            print("푸시 알람 시간 불러오기 실패: \(error.localizedDescription)")
            if !self.showAlert {
                self.alertMsg = "푸시 알람 시간을 불러오는 중 오류가 발생했습니다."
                self.showAlert = true
            }
        }
    }
    
    func updatePushNotificationEnabled() async {
        if !self.isConnected { return }
        
        do {
            self.isLoading = true
            defer { self.isLoading = false }
            
            guard let userId = self.authSvc.user?.uid else { return }
            try await self.userSvc.updatePushNotificationEnabled(userId, enabled: self.pushNotificationEnabled)
        } catch {
            print("푸시 알람 활성화 여부 업데이트 실패: \(error.localizedDescription)")
            self.alertMsg = "푸시 알람 활성화 여부를 업데이트하는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func updatePushNotificationTime() async {
        if !self.isConnected { return }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            guard let userId = self.authSvc.user?.uid else { return }
            
            try await self.userSvc.updatePushNoficationTime(userId, time: pushNotificationTime)
            
        } catch {
            print("푸시 알람 시간 업데이트 실패: \(error.localizedDescription)")
            self.alertMsg = "푸시 알람 시간을 업데이트하는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func updateAppTheme() async {
        if !self.isConnected { return }
        
        do {
            self.isLoading = true
            defer { self.isLoading = false }
            
            guard let userId = self.authSvc.user?.uid,
                  let theme = SystemTheme(rawValue: self.theme) else { return }
            try await self.userSvc.updateAppTheme(userId, theme: theme.rawValue)
        } catch {
            print("앱 테마 업데이트 실패: \(error.localizedDescription)")
            self.alertMsg = "앱 테마를 업데이트하는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
}
