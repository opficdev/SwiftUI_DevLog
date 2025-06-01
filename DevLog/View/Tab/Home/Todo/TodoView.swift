//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @State private var kind: TaskKind
    @State private var tasks: [String] = [] // 예시 데이터
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var showIssueFullScreen: Bool = false
    
    init(_ kind: TaskKind) {
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
                    ToolbarItem(placement: .topBarTrailing) {
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
