//
//  HomeViewModel.swift
//  DevLog
//
//  Created by opfic on 6/17/25.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    private let todoSvc: TodoService
    
    @Published var pinnedTodos: [Todo] = []
    @Published var showError: Bool = false
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, todoSvc: TodoService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.todoSvc = todoSvc
        
        // self.isLoading -> network.isLoading 단방향 연결
        self.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &self.networkSvc.$isLoading)
        
        // NetworkActivityService.isConnected -> self.isConnected 단방향 연결
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
    }
    
    func requestPinnedTodos() async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            self.pinnedTodos = try await self.todoSvc.requestPinnedTodoList(userId: userId)
            
        } catch {
            showError = true
        }
    }
}
