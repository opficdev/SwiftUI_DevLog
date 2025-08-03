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
    private let notiSvc: NotificationService
    @Published var todoIds: [String] = []
    @Published var showAlert: Bool = false
    @Published var alertMsg: String = ""
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = true
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, notiSvc: NotificationService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.notiSvc = notiSvc
        
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
    }
    
    func requestNotifications() async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            defer {
                self.isLoading = false
            }
            
//            self.notifications = try await self.notiSvc.requestNotification(userId: userId)
            
        } catch {
            print("Error requesting notifications: \(error.localizedDescription)")
            self.alertMsg = "푸시 알람 목록을 불러오는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
    
    func deleteNotification(notificationId: String) async {
        if !self.isConnected { return }
        do {
            self.isLoading = true
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            defer {
                self.isLoading = false
            }
            
//            self.notifications.removeAll { $0.id == notificationId }
            
            try await self.notiSvc.deleteNotification(notificationId: notificationId, userId: userId)
            
        } catch {
            print("Error deleting notification: \(error.localizedDescription)")
            self.alertMsg = "푸시 알람을 삭제하는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
}
