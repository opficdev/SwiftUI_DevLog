//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @StateObject private var todoVM: TodoViewModel
    @State private var searchText: String = ""
    @State private var showIssueFullScreen: Bool = false
    
    init(auth: AuthService, kind: TodoKind) {
        self._todoVM = StateObject(wrappedValue: TodoViewModel(auth: auth, kind: kind))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if todoVM.todos.isEmpty {
                            VStack {
                                Spacer()
                                Text("작성된 내용이 없습니다.")
                                    .foregroundStyle(Color.gray)
                                Spacer()
                            }
                            .frame(height: geometry.size.height)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        else {
                            ForEach(todoVM.todos.filter { searchText.isEmpty ||
                                $0.title.localizedCaseInsensitiveContains(searchText) ||
                                $0.content.localizedCaseInsensitiveContains(searchText) }, id: \.id) { task in
//                                NavigationLink(destination: PostDetailView(task: task).environmentObject(firebaseVM)) {
//
//                                }
                            }
                        }
                    }
                }
                .navigationTitle(todoVM.kind.localizedName)
                .fullScreenCover(isPresented: $showIssueFullScreen) {
                    PostEditorView(title: "새 \(todoVM.kind.localizedName)", kind: todoVM.kind)
                        .environmentObject(todoVM)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Menu(content: {
                            Section {
                                Button(action: {
                                    
                                }) {
                                    Text("정렬: 최신")
                                }
                                Button(action: {
                                    
                                }) {
                                    Text("상위: 전체")
                                }
                                Button(action: {
                                    
                                }) {
                                    Text("상위: 어제")
                                }
                                Button(action: {
                                    
                                }) {
                                    Text("상위: 지난주")
                                }
                                Button(action: {
                                    
                                }) {
                                    Text("상위: 지난달")
                                }
                                Button(action: {
                                    
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
                            showIssueFullScreen = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "\(todoVM.kind.localizedName) 검색"
                )
            }
        }
        .onAppear {
            Task {
                do {
                    try await todoVM.requestTodoList()
                } catch {
                    
                }
            }
        }
    }
}
