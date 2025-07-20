//
//  LoginViewModel.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    // AuthService, NetworkActivityService, UserService 인스턴스
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    private let userSvc: UserService
    
    private var didSignedInBySession = true
    private var cancellables = Set<AnyCancellable>()
    
    @Published var signIn: Bool? = nil
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
        
        NotificationCenter.default.publisher(for: .fcmToken)
            .compactMap { $0.userInfo?["fcmToken"] as? String }
            .sink { [weak self] fcmToken in
                guard let self = self, let user = self.authSvc.user else { return }
                Task {
                    try await self.userSvc.upsertUser(user: user, fcmToken: fcmToken)
                    try await self.userSvc.fetchUserInfo(user: user)
                    self.signIn = true
                }
            }
            .store(in: &self.cancellables)
        
        // NetworkActivityService.isConnected를 self.isConnected와와 단방향 연결
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
        
        // NetworkActivityService.showNetworkAlert를 self.showNetworkAlert와 단방향 연결
        self.networkSvc.$showNetworkAlert
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$showNetworkAlert)
    }
    
    func signInWithApple() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            let (user, fcmToken) = try await self.authSvc.signInWithApple()
            
            try await self.userSvc.upsertUser(user: user, fcmToken: fcmToken, provider: "apple.com")
            
            try await self.userSvc.fetchUserInfo(user: self.authSvc.user!)
            
            self.signIn = true
            
        } catch {
            print("Error signing in with Apple: \(error.localizedDescription)")
            self.alertMsg = "로그인에 실패했습니다. 다시 시도해주세요."
            self.showAlert = true
        }
    }
    
    func signInWithGithub() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            let (user, fcmToken, accessToken) = try await self.authSvc.signInWithGithub()
            
            try await self.userSvc.upsertUser(user: user, fcmToken: fcmToken, provider: "github.com", accessToken: accessToken)
            
            try await self.userSvc.fetchUserInfo(user: self.authSvc.user!)
            
            self.signIn = true
            
        } catch {
            print("Error signing in with GitHub: \(error.localizedDescription)")
            self.alertMsg = "로그인에 실패했습니다. 다시 시도해주세요."
            self.showAlert = true
        }
    }
    
    func signInWithGoogle() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            let (user, fcmToken) = try await self.authSvc.signInWithGoogle()
            
            try await self.userSvc.upsertUser(user: user, fcmToken: fcmToken, provider: "google.com")
            
            try await self.userSvc.fetchUserInfo(user: self.authSvc.user!)
            
            self.signIn = true
            
        } catch {
            print("Error signing in with Google: \(error.localizedDescription)")
            self.alertMsg = "로그인에 실패했습니다. 다시 시도해주세요."
            self.showAlert = true
        }
    }
    
    func signOut() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.authSvc.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.alertMsg = "로그아웃에 실패했습니다. 다시 시도해주세요."
            self.showAlert = true
        }
    }
}
