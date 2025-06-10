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
    @Published var email = ""
    
    // UserInfo
    @Published var avatar = Image(systemName: "person.crop.circle.fill")
    @Published var name = ""
    @Published var statusMsg = ""

    @Published var showAlert = false
    @Published var alertMsg = ""
    
    init(authSvc: AuthService, userSvc: UserService) {
        self.authSvc = authSvc
        self.userSvc = userSvc
        
        
        self.authSvc.$email
            .receive(on: DispatchQueue.main)
            .assign(to: &$email)
        
        
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
            self.showAlert = true
        }
    }
}
