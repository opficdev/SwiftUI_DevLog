//
//  TodoViewModel.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import SwiftUI

@MainActor
final class TodoViewModel: ObservableObject {
    private let todoService = TodoService()
    @ObservedObject private var authService: AuthService
    @Published var todos: [Todo] = []
    @Published var kind: TodoKind
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    init(auth: AuthService, kind: TodoKind) {
        self.authService = auth
        self.kind = kind
    }

    func requestTodoList() async {
        do {
            guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
        
            self.todos = try await todoService.requestTodoList(kind: self.kind, userId: userId)
        } catch {
            print("Error requesting todos: \(error.localizedDescription)")
            errorMessage = "TODO 목록을 불러오는 중 오류가 발생했습니다."
            showError = true
        }
    }
    
    func upsertTodoTask(_ todo: Todo) async {
        do {
            guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
        
            try await todoService.upsertTodoTask(todo: todo, userId: userId)
        } catch {
            print("Error upserting todo: \(error.localizedDescription)")
            errorMessage = "TODO를 저장하는 중 오류가 발생했습니다."
            showError = true
        }
    }
    
    func deleteTodoTask(_ todo: Todo) async {
        do {
            guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
            
            try await todoService.deleteTodoTask(todo: todo, userId: userId)
        } catch {
            print("Error deleting todo: \(error.localizedDescription)")
            errorMessage = "TODO를 삭제하는 중 오류가 발생했습니다."
            showError = true
        }
    }
}
