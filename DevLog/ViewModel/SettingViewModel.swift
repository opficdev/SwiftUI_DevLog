//
//  SettingViewModel.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import UIKit

@MainActor
class SettingViewModel: ObservableObject {
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    private let userSvc: UserService
    @Published var theme: String = ""
    @Published var appIcon: String = ""
    
    @Published var showAlert: Bool = false
    @Published var alertMsg: String = ""
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    @Published var showNetworkAlert: Bool = false

    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, userSvc: UserService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.userSvc = userSvc
    
        // self.isLoading을 network.isLoading와 단방향 연결
        self.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &self.networkSvc.$isLoading)
        
        // NetworkActivityService.isConnected를 self.isConnected와와 단방향 연결
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
        
        // NetworkActivityService.showNetworkAlert를 self.showNetworkAlert와 단방향 연결
        self.networkSvc.$showNetworkAlert
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$showNetworkAlert)
    }
    
    func setAppIcon(iconName: String? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    continuation.resume()
                }
            }
        }
    }
    
    func signOut() async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            guard let user = self.authSvc.user else { throw URLError(.userAuthenticationRequired) }
            
            try await self.authSvc.signOut(user: user)
            
            // AppStorage 전체를 삭제하는 코드
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.alertMsg = "로그아웃 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func deleteUser() async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            guard let user = self.authSvc.user else { throw URLError(.userAuthenticationRequired) }
            
            try await self.userSvc.deleteUser(user: user)
            
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        } catch {
            print("Error deleting user: \(error.localizedDescription)")
            self.alertMsg = "회원탈퇴 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
}
