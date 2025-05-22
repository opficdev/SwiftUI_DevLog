//
//  SearchView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var isFocused: Bool = false
    
    var body: some View {
        NavigationStack {
            SearchedView(searchText: $searchText, focused: $isFocused)
                .searchable(text: $searchText, prompt: "DevLog 검색")
            GeometryReader { geometry in
                ScrollView {
                    VStack{
                        if isFocused {
                            Divider()
                            if searchText.isEmpty {
                                Spacer()
                                Text("앱 내 컨텐츠나 개발자 문서를 검색할 수 있어요.")
                                Spacer()
                            }
                            else {
                                Text("검색 내용이 보여지는 곳")
                            }
                        }
                        else {
                            
                        }
                    }
                    .frame(width: geometry.size.width)
                    .frame(minHeight: isFocused && searchText.isEmpty ? geometry.size.height : 0)
                }
                .navigationTitle("검색")
            }
        }
    }
}
