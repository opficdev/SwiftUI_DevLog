//
//  HomeView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import SwiftUIIntrospect


struct HomeView: View {
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack {
                    SearchableView(searchText: $searchText, isSearching: $isSearching)
                        .searchable(text: $searchText, prompt: "DevLog 검색")
                    List {
                        Section(content: {
                            
                        }, header: {
                            HStack {
                                Text("TODO")
                                    .foregroundStyle(Color.primary)
                                    .font(.headline)
                                    .bold()
                                Spacer()
                                Menu {
                                    
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundStyle(Color.gray)
                                }
                            }
                            .listRowInsets(EdgeInsets())    //  헤더의 padding 제거
                        })
                    }
                }
            }
            .navigationTitle("홈")
        }
    }
}

#Preview {
    HomeView()
}
