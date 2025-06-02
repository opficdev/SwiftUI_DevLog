//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @State private var kind: TodoKind
    @State private var tasks: [String] = [] // 예시 데이터
    @State private var searchText: String = ""
    @State private var showIssueFullScreen: Bool = false
    
    init(_ kind: TodoKind) {
        self._kind = State(initialValue: kind)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack {
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
                            ForEach(tasks.filter { $0.contains(searchText) }, id: \.self) { issue in
                                Text(issue)
                            }
                        }
                    }
                }
                .navigationTitle(kind.localizedName)
                .fullScreenCover(isPresented: $showIssueFullScreen) {
                    PostEditorView("새 \(kind.localizedName)")
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
    }
}

#Preview {
    TodoView(.issue)
}
