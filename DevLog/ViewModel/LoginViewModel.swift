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
    private var didSignedInBySession = true
    private var cancellables = Set<AnyCancellable>()
    
    @Published var signIn: Bool? = nil
    @Published var showError: Bool = false
    @Published var errorMsg: String = ""
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    @Published var showNetworkAlert: Bool = false
    
    // AuthService와 NetworkActivityService의 인스턴스
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        
        // auth.user가 nil이면 signIn을 false로 설정
        self.authSvc.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                self.signIn = user != nil
            }
            .store(in: &self.cancellables)
    
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
    
    func signInWithApple() async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            try await self.authSvc.signInWithApple()
            
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
            
            try await self.authSvc.signInWithGithub()
            
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
            
            try await self.authSvc.signInWithGoogle()
            
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
            
            guard let user = self.authSvc.user else { throw URLError(.userAuthenticationRequired) }
            
            try await self.authSvc.signOut(user: user)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.errorMsg = "로그아웃에 실패했습니다. 다시 시도해주세요."
            self.showError = true
        }
    }
}
