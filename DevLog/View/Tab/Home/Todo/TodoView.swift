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
                        .swipeActions(edge: .trailing) {
                            //  맨 위에 있는 버튼에만 fullSwipe 액션이 적용됨
                            Button(role: .destructive, action: {
                                Task {
                                    await todoVM.deleteTodo(todo)
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                            Button(action: {
                                Task {
                                    await todoVM.togglePin(todo)
                                }
                            }) {
                                Image(systemName: "star\(todo.isPinned ? ".slash" : ".fill")")
                            }
                            .tint(Color.orange)
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
                                todoVM.filterOption = .create
                            }) {
                                if todoVM.filterOption == .create {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("생성")
                            }
                            Button(action: {
                                todoVM.filterOption = .update
                            }) {
                                if todoVM.filterOption == .update {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("수정")
                            }
                        } header: {
                            Text("정렬 옵션")
                        }
                        
                        Section {
                            Button(action: {
                                todoVM.filterOption = .day
                            }) {
                                if todoVM.filterOption == .day {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("어제")
                            }
                            Button(action: {
                                todoVM.filterOption = .week
                            }) {
                                if todoVM.filterOption == .week {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("지난주")
                            }
                            Button(action: {
                                todoVM.filterOption = .month
                            }) {
                                if todoVM.filterOption == .month {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("지난달")
                            }
                            Button(action: {
                               
                                todoVM.filterOption = .year
                            }) {
                                if todoVM.filterOption == .year {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("작년")
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
