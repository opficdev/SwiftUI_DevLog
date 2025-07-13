//
//  NotificationViewModel.swift
//  DevLog
//
//  Created by opfic on 6/27/25.
//

import Foundation

@MainActor
class NotificationViewModel: ObservableObject {
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    @Published var notifications: [PushNotification] = []
    @Published var showAlert: Bool = false
    @Published var alertMsg: String = ""
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = true
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
    }
    
    func requestNotifications() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            
            
        } catch {
            self.alertMsg = "푸시 알람 목록을 불러오는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
}
