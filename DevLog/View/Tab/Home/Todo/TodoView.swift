//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @StateObject private var todoVM: TodoViewModel
    @State private var showEditor: Bool = false
    
    init(todoVM: TodoViewModel) {
        self._todoVM = StateObject(wrappedValue: todoVM)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if todoVM.filteredTodos.isEmpty {
                    VStack {
                        Spacer()
                        Text("작성된 내용이 없습니다.")
                            .foregroundStyle(Color.gray)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                else {
                    List(todoVM.filteredTodos) { todo in
                        NavigationLink(destination: TodoDetailView(todo: todo).environmentObject(todoVM)) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    if todo.isPinned {
                                        Image(systemName: "star.fill")
                                            .font(.headline)
                                            .foregroundStyle(Color.orange)
                                    }
                                    Text(todo.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                }
                                Text(todo.content)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 5)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button(action: {
                                Task {
                                    await todoVM.togglePin(todo)
                                }
                            }) {
                                Image(systemName: "star\(todo.isPinned ? ".slash" : ".fill")")
                            }
                            .tint(Color.orange)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive, action: {
                                Task {
                                    await todoVM.deleteTodo(todo)
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(todoVM.kind.localizedName)
            .fullScreenCover(isPresented: $showEditor) {
                TodoEditorView(title: "새 \(todoVM.kind.localizedName)")
                    .environmentObject(todoVM)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu(content: {
                        Section {
                            Button(action: {
                                todoVM.filteredTodos.sort(by: { $0.createdAt > $1.createdAt })
                            }) {
                                Text("정렬: 최신")
                            }
                            Button(action: {
                                todoVM.filterTodoList(by: TodoViewModel.FilterPeriod.day)
                            }) {
                                Text("상위: 어제")
                            }
                            Button(action: {
                                todoVM.filterTodoList(by: TodoViewModel.FilterPeriod.week)
                            }) {
                                Text("상위: 지난주")
                            }
                            Button(action: {
                                todoVM.filterTodoList(by: TodoViewModel.FilterPeriod.month)
                            }) {
                                Text("상위: 지난달")
                            }
                            Button(action: {
                                todoVM.filterTodoList(by: TodoViewModel.FilterPeriod.year)
                            }) {
                                Text("상위: 작년")
                            }
                        } header: {
                            Text("필터 옵션")
                        }
                    }, label: {
                        Image(systemName: "ellipsis")
                    })
                    Button(action: {
                        showEditor = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(
                text: $todoVM.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "\(todoVM.kind.localizedName) 검색"
            )
            .searchScopes($todoVM.scope) {
                ForEach(TodoScope.allCases, id: \.self) { scope in
                    Text(scope.localizedName).tag(scope)
                }
            }
            .onAppear {
                Task {
                    await todoVM.requestTodoList()
                }
            }
        }
    }
}
