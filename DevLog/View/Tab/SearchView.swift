//
//  SearchView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var showDoneBtn: Bool = false
    @FocusState private var focusedOnSearch: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("DevLog 검색", text: $searchText)
                                .focused($focusedOnSearch)
                            
                            if !searchText.isEmpty && showDoneBtn {
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .foregroundStyle(Color.gray)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray5))
                        )
                        if showDoneBtn {
                            Button(action: {
                                focusedOnSearch = false
                                Task {
                                    do {
                                        
                                    } catch {
                                        
                                    }
                                }
                            }) {
                                Text("완료")
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("검색")
        .onChange(of: focusedOnSearch) { newValue in
            withAnimation {
                showDoneBtn = newValue
            }
        }
    }
}

#Preview {
    SearchView()
}
