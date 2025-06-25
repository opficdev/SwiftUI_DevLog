//
//  HomeViewModel.swift
//  DevLog
//
//  Created by opfic on 6/17/25.
//

import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    private let todoSvc: TodoService
    
    // HomeView
    @Published var pinnedTodos: [Todo] = []
    @Published var alertMsg: String = ""
    @Published var showAlert: Bool = false
    
    // TodoManageView
    @AppStorage("todoKindStrings") var todoKindStrings: [String] = TodoKind.allCases.sorted { $0.localizedName < $1.localizedName }.map { $0.rawValue } {
        didSet {
            self.todoKinds = self.todoKindStrings.compactMap { TodoKind(rawValue: $0) }
            objectWillChange.send()
        }
    }
    @Published var todoKinds: [TodoKind] = []
    
    // HomeView, TodoManageView
    @AppStorage("selectedTodoKindStrings") var selectedTodoKindStrings: [String] = TodoKind.allCases.sorted { $0.localizedName < $1.localizedName }.map { $0.rawValue } {
        didSet {
            self.selectedTodoKinds = self.selectedTodoKindStrings.compactMap { TodoKind(rawValue: $0) }
        }
    }
    @Published var selectedTodoKinds: [TodoKind] = []
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, todoSvc: TodoService) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.todoSvc = todoSvc
        
        self.todoKinds = self.todoKindStrings.compactMap { TodoKind(rawValue: $0) }                     //  초기값 지정
        self.selectedTodoKinds = self.selectedTodoKindStrings.compactMap { TodoKind(rawValue: $0) }     //  초기값 지정
        
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
            print("Error requesting pinned todos: \(error.localizedDescription)")
            self.alertMsg = "중요 표시된 TODO 목록을 불러오는 중 오류가 발생했습니다."
            self.showAlert = true
        }
    }
}
