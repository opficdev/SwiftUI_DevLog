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
    
    // NetworkActivityService와 연결되는 Published 프로퍼티
    @Published var isConnected: Bool = true
    @Published var isLoading: Bool = false
    
    enum FilterPeriod {
        case day, week, month, year
    }
    
    init(authSvc: AuthService, networkSvc: NetworkActivityService, todoSvc: TodoService, kind: TodoKind) {
        self.authSvc = authSvc
        self.networkSvc = networkSvc
        self.todoSvc = todoSvc
        self.kind = kind
        
        self.$searchText
            .combineLatest(self.$scope, self.$todos) // <--- self.$todos 추가!
            .map { [weak self] searchText, scope, currentTodos -> [Todo] in // currentTodos 파라미터로 받기
                guard let _ = self else { return [] }

                if searchText.isEmpty {
                    return currentTodos // 스트림에서 온 최신 todos (데이터 로드 후의 값)
                }
                else {
                    return currentTodos.filter { todo in // 여기서도 currentTodos 사용
                        switch scope {
                        case .title:
                            return todo.title.localizedCaseInsensitiveContains(searchText)
                        case .content:
                            return todo.content.localizedCaseInsensitiveContains(searchText)
                        }
                    }
                }
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
        do {
            self.isLoading = true
            defer {
                self.isLoading = false
            }
            self.todos.removeAll { $0.id == todo.id }
            self.filteredTodos.removeAll { $0.id == todo.id }
            
            guard let userId = self.authSvc.userId else { throw URLError(.userAuthenticationRequired) }
            
            try await self.todoSvc.deleteTodo(todo: todo, userId: userId)
        } catch {
            print("Error deleting todo: \(error.localizedDescription)")
            // 로직 상 하위 2줄의 변수에서 todo가 존재하지 않았을 수 없음
            self.todos.append(todo) // 삭제 실패 시 원래 목록에 다시 추가
            self.filteredTodos.append(todo) // 필터링된 목록에도 다시 추가
            errorMsg = "TODO를 삭제하는 중 오류가 발생했습니다."
            showError = true
        }
    }
    
    func filterTodoList(by component: FilterPeriod) {
        self.filteredTodos = self.filteredTodos.filter { todo in
            var newDate: Date? = nil
            
            switch component {
            case .day:
                newDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
            case .week:
                newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())
            case .month:
                newDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
            case .year:
                newDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
            }
            
            guard let newDate = newDate else { return false }
            
            return newDate <= todo.createdAt
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
            errorMsg = "TODO 고정 상태를 변경하는 중 오류가 발생했습니다."
            showError = true
        }
    }
}
