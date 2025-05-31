//
//  IssueView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct IssueView: View {
    @State private var issues: [String] = [] // 예시 데이터
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var selectedCategory: String = "전체"
    @State private var showIssueFullScreen: Bool = false
    
    var body: some View {
        VStack {
            SearchableView(isSearching: $isSearching)
                .searchable(text: $searchText, prompt: "이슈 검색")
            GeometryReader { geometry in
                List {
                    if issues.isEmpty {
                        VStack {
                            Spacer()
                            Text("작성된 이슈가 없습니다.")
                                .foregroundStyle(Color.gray)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .frame(height: geometry.size.height)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    else {
                        ForEach(issues.filter { $0.contains(searchText) }, id: \.self) { issue in
                            Text(issue)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .fullScreenCover(isPresented: $showIssueFullScreen) {
            PostEditorView("이슈 작성")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showIssueFullScreen = true
                }) {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

#Preview {
    IssueView()
}
