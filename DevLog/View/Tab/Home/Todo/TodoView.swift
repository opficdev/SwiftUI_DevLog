//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @EnvironmentObject private var firebaseVM: FirebaseViewModel
    @State private var kind: TodoKind
    @State private var tasks: [Todo] = [] // 예시 데이터
    @State private var searchText: String = ""
    @State private var showIssueFullScreen: Bool = false
    
    init(_ kind: TodoKind) {
        self._kind = State(initialValue: kind)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if tasks.isEmpty {
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
                            ForEach(tasks.filter { searchText.isEmpty ||
                                $0.title.localizedCaseInsensitiveContains(searchText) ||
                                $0.content.localizedCaseInsensitiveContains(searchText) }, id: \.id) { task in
//                                NavigationLink(destination: PostDetailView(task: task).environmentObject(firebaseVM)) {
//
//                                }
                            }
                        }
                    }
                }
                .navigationTitle(kind.localizedName)
                .fullScreenCover(isPresented: $showIssueFullScreen) {
                    PostEditorView(title: "새 \(kind.localizedName)", kind: kind)
                        .environmentObject(firebaseVM)
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
                    prompt: "\(kind.localizedName) 검색"
                )
            }
        }
        .onAppear {
            Task {
                do {
                    self.tasks = try await firebaseVM.requestTodoList(kind)
                } catch {
                    
                }
            }
        }
    }
}

#Preview {
    TodoView(.issue)
        .environmentObject(FirebaseViewModel())
}
