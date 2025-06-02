//
//  TodoViewModel.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import SwiftUI

@MainActor
final class TodoViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var kind: TodoKind
    @ObservedObject private var authService: AuthService
    private let todoService = TodoService()
    
    init(auth: AuthService, kind: TodoKind) {
        self.authService = auth
        self.kind = kind
    }

    func requestTodoList() async throws {
        guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
        
        do {
            self.todos = try await todoService.requestTodoList(kind: kind, userId: userId)
        } catch {
            print("Error requesting todos: \(error.localizedDescription)")
            throw error
        }
    }
    
    func upsertTodo(_ todo: Todo) async throws {
        guard let userId = authService.userId else { throw URLError(.userAuthenticationRequired) }
        
        do {
            try await todoService.upsertTodoList(todo: todo, userId: userId)
        } catch {
            print("Error upserting todo: \(error.localizedDescription)")
            throw error
        }
    }
}
