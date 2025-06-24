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
    private let authSvc: AuthService
    private let networkSvc: NetworkActivityService
    private let todoSvc: TodoService
    private var cancellables: Set<AnyCancellable> = []
    @Published private var todos: [Todo] = []
    @Published var filteredTodos: [Todo] = []
    @Published var searchText: String = ""
    @Published var kind: TodoKind
    @Published var showAlert: Bool = false
    @Published var alertMsg: String = ""
    @Published var scope: TodoScope = .title
    @Published var filterOption: FilterOption = .create
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    
    enum FilterOption {
        case create, update, day, week, month, year
    }
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, todoSvc: TodoService, kind: TodoKind) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.todoSvc = todoSvc
        self.kind = kind
        
        self.$searchText
            .combineLatest(self.$scope, self.$todos, self.$filterOption)
            .map { [weak self] searchText, scope, currentTodos, option -> [Todo] in
                guard let _ = self else { return [] }
                
                var newTodos: [Todo] = []
                
                switch option {
                case .create:
                    newTodos = currentTodos
                case .update:
                    newTodos = currentTodos.sorted { $0.updatedAt > $1.updatedAt }
                case .day:
                    newTodos = newTodos.filter { todo in
                        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                        return oneDayAgo <= todo.createdAt
                    }
                case .week:
                    newTodos = newTodos.filter { todo in
                        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
                        return oneWeekAgo <= todo.createdAt
                    }
                case .month:
                    newTodos = newTodos.filter { todo in
                        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                        return oneMonthAgo <= todo.createdAt
                    }
                case .year:
                    newTodos = newTodos.filter { todo in
                        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
                        return oneYearAgo <= todo.createdAt
                    }
                }
                
                if !searchText.isEmpty {
                    return newTodos.filter { todo in
                        switch scope {
                        case .title:
                            return todo.title.localizedCaseInsensitiveContains(searchText)
                        case .content:
                            return todo.content.localizedCaseInsensitiveContains(searchText)
                        }
                    }
                }
                return newTodos
            }
            .receive(on: DispatchQueue.main) // UI 업데이트는 메인 스레드
            .assign(to: &$filteredTodos)
        
        // self.isLoading -> network.isLoading 단방향 연결
        self.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &self.networkSvc.$isLoading)
        
        // NetworkActivityService.isConnected -> self.isConnected 단방향 연결
        self.networkSvc.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$isConnected)
    }

    func requestTodoList() async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
        
            self.todos = try await self.todoSvc.requestTodoList(kind: self.kind, userId: userId)
        } catch {
            print("Error requesting todos: \(error.localizedDescription)")
            alertMsg = "TODO 목록을 불러오는 중 오류가 발생했습니다."
            showAlert = true
        }
    }
    
    func upsertTodo(_ todo: Todo) async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
        
            try await self.todoSvc.upsertTodo(todo: todo, userId: userId)
        } catch {
            print("Error upserting todo: \(error.localizedDescription)")
            alertMsg = "TODO를 저장하는 중 오류가 발생했습니다."
            showAlert = true
        }
    }
    
    func deleteTodo(_ todo: Todo) async {
        guard let todosIndex = self.todos.firstIndex(where: { $0.id == todo.id }),
              let filteredTodosIndex = self.filteredTodos.firstIndex(where: { $0.id == todo.id }) else { return }
        
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            var a = 1
            
            self.todos.remove(at: todosIndex)
            self.filteredTodos.remove(at: filteredTodosIndex)
            
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            try await self.todoSvc.deleteTodo(todo: todo, userId: userId)
        } catch {
            print("Error deleting todo: \(error.localizedDescription)")
            // 로직 상 하위 2줄의 변수에서 todo가 존재하지 않았을 수 없음
            self.todos.insert(todo, at: todosIndex) // 원래 위치에 다시 추가
            self.filteredTodos.insert(todo, at: filteredTodosIndex) // 원래 위치에 다시 추가
            alertMsg = "TODO를 삭제하는 중 오류가 발생했습니다."
            showAlert = true
        }
    }
    
    func togglePin(_ todo: Todo) async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            var updatedTodo = todo
            
            updatedTodo.isPinned.toggle()
            
            if let idx = self.todos.firstIndex(where: { $0.id == todo.id }) {
                self.todos[idx] = updatedTodo
            }
            
            if let filteredIdx = self.filteredTodos.firstIndex(where: { $0.id == todo.id }) {
                self.filteredTodos[filteredIdx] = updatedTodo
            }
            
            try await self.todoSvc.upsertTodo(todo: updatedTodo, userId: userId)
        } catch {
            print("Error toggling pin: \(error.localizedDescription)")
            alertMsg = "TODO 중요 표시를 변경하는 중 오류가 발생했습니다."
            showAlert = true
        }
    }
    
    func toggleComplete(_ todo: Todo) async {
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            var updatedTodo = todo
            
            updatedTodo.isCompleted.toggle()
            
            if let idx = self.todos.firstIndex(where: { $0.id == todo.id }) {
                self.todos[idx] = updatedTodo
            }
            
            if let filteredIdx = self.filteredTodos.firstIndex(where: { $0.id == todo.id }) {
                self.filteredTodos[filteredIdx] = updatedTodo
            }
            
            try await self.todoSvc.upsertTodo(todo: updatedTodo, userId: userId)
        } catch {
            print("Error toggling complete: \(error.localizedDescription)")
            alertMsg = "TODO 완료 표시를 변경하는 중 오류가 발생했습니다."
            showAlert = true
        }
    }
}
