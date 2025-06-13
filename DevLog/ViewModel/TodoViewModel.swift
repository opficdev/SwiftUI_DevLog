//
//  TodoViewModel.swift
//  DevLog
//
//  Created by opfic on 6/2/25.
//

import SwiftUI
import Combine

@MainActor
final class TodoViewModel: ObservableObject {
    private let todoSvc: TodoService
    private let authSvc: AuthService
    private var cancellables: Set<AnyCancellable> = []
    @Published var todos: [Todo] = []
    @Published var searchText: String = ""
    @Published var kind: TodoKind
    @Published var showError: Bool = false
    @Published var errorMsg: String = ""
    @Published var scope: TodoScope = .title
    
    init(authSvc: AuthService, todoSvc: TodoService, kind: TodoKind) {
        self.authSvc = authSvc
        self.todoSvc = todoSvc
        self.kind = kind
        
        $searchText
            .combineLatest($scope)
            .map { searchText, scope in
                if searchText.isEmpty {
                    return self.todos
                } else {
                    return self.todos.filter { todo in
                        switch scope {
                        case .title:
                            return todo.title.localizedCaseInsensitiveContains(searchText)
                        case .content:
                            return todo.content.localizedCaseInsensitiveContains(searchText)
                        }
                    }
                }
            }
            .assign(to: &$todos)
    }

    func requestTodoList() async {
        do {
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
        
            self.todos = try await self.todoSvc.requestTodoList(kind: self.kind, userId: userId)
        } catch {
            print("Error requesting todos: \(error.localizedDescription)")
            errorMsg = "TODO 목록을 불러오는 중 오류가 발생했습니다."
            showError = true
        }
    }
    
    func upsertTodoTask(_ todo: Todo) async {
        do {
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
        
            try await self.todoSvc.upsertTodoTask(todo: todo, userId: userId)
        } catch {
            print("Error upserting todo: \(error.localizedDescription)")
            errorMsg = "TODO를 저장하는 중 오류가 발생했습니다."
            showError = true
        }
    }
    
    func deleteTodoTask(_ todo: Todo) async {
        do {
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            try await self.todoSvc.deleteTodoTask(todo: todo, userId: userId)
        } catch {
            print("Error deleting todo: \(error.localizedDescription)")
            errorMsg = "TODO를 삭제하는 중 오류가 발생했습니다."
            showError = true
        }
    }
}
