//
//  ProfileViewModel.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import Combine
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    private let authSvc: AuthService
    private let userSvc: UserService
    
    // AuthInfo
    @Published var currentProvider = ""
    @Published var email = ""
    @Published var providers: [String] = []
    
    // UserInfo
    @Published var avatar = Image(systemName: "person.crop.circle.fill")
    @Published var name = ""
    @Published var statusMsg = ""

    @Published var showProfileAlert = false //  ProfileView에서 alert를 표시하기 위한 변수
    @Published var showAccountAlert = false //  AccountView에서 alert를 표시하기 위한 변수
    @Published var alertMsg = ""
    
    init(authSvc: AuthService, userSvc: UserService) {
        self.authSvc = authSvc
        self.userSvc = userSvc
        
        self.authSvc.$currentProvider
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentProvider)
        
        self.authSvc.$email
            .receive(on: DispatchQueue.main)
            .assign(to: &$email)
        
        self.authSvc.$providers
            .receive(on: DispatchQueue.main)
            .assign(to: &$providers)
        
        self.userSvc.$avatar
            .receive(on: DispatchQueue.main)
            .assign(to: &$avatar)
        
        self.userSvc.$name
            .receive(on: DispatchQueue.main)
            .assign(to: &$name)
        
        self.userSvc.$statusMsg
            .receive(on: DispatchQueue.main)
            .assign(to: &$statusMsg)
    }

    func upsertStatusMsg() async {
        do {
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            try await self.userSvc.upsertStatusMsg(userId: userId, statusMsg: self.statusMsg)
        } catch {
            print("Error updating status message: \(error.localizedDescription)")
            self.alertMsg = "상태 메시지를 업데이트하는 중 오류가 발생했습니다."
            self.showProfileAlert = true
        }
    }
    
    func linkWithProvider(provider: String) async {
        do {
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
            
            self.showAccountAlert = true
        }
    }
    
    func unlinkFromProvider(provider: String) async {
        do {
            try await self.authSvc.unlinkFromProvider(provider: provider)
            
        } catch {
            print("Error unlinking with provider: \(error.localizedDescription)")
            
            self.showAccountAlert = true
        }
    }
    
}
