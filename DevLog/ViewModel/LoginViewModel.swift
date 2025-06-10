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
    @Published var showError: Bool = false
    @Published var errorMsg: String = ""
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    @Published var showNetworkAlert: Bool = false
    
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, userSvc: UserService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.userSvc = userSvc
        
        // auth.user가 nil이면 signIn을 false로 설정
        self.authSvc.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                if let user = user {
                    if self.signIn == nil { // 기존 세션을 통해 로그인이 된 경우
                        Task {
                            try await self.userSvc.fetchUserInfo(user: user)
                            self.signIn = true
                        }
                    }
                }
                else {
                    self.signIn = false
                }
            }
            .store(in: &self.cancellables)
        
         self.$isLoading
             .removeDuplicates() // 중복 값 전파 방지
             .receive(on: DispatchQueue.main)
             .assign(to: \.isLoading, on: self.networkSvc) // networkSvc 객체의 isLoading 프로퍼티에 할당
             .store(in: &self.cancellables)

         // networkSvc.isLoading -> Service.isLoading 바인딩
         self.networkSvc.$isLoading
             .removeDuplicates() // 중복 값 전파 방지
             .receive(on: DispatchQueue.main)
             .assign(to: \.isLoading, on: self) // 뷰모델의 isLoading @Published 프로퍼티에 할당
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
            self.errorMsg = "로그인에 실패했습니다. 다시 시도해주세요."
            self.showError = true
        }
    }
    
    func signInWithGithub() async {
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
            self.errorMsg = "로그인에 실패했습니다. 다시 시도해주세요."
            self.showError = true
        }
    }
    
    func signInWithGoogle() async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            let (user, fcmToken) = try await self.authSvc.signInWithGoogle()
            
            try await self.userSvc.upsertUser(user: user, fcmToken: fcmToken, provider: "google.com")
            
            self.signIn = true
            
        } catch {
            print("Error signing in with Google: \(error.localizedDescription)")
            self.errorMsg = "로그인에 실패했습니다. 다시 시도해주세요."
            self.showError = true
        }
    }
    
    func signOut() async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.authSvc.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.errorMsg = "로그아웃에 실패했습니다. 다시 시도해주세요."
            self.showError = true
        }
    }
}
