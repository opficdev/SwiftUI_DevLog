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
    @State private var taskKinds = TaskKind.allCases
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack {
                    SearchableView(searchText: $searchText, isSearching: $isSearching)
                        .searchable(text: $searchText, prompt: "DevLog 검색")
                    List {
                        Section(content: {
                            ForEach(taskKinds.sorted(by: { $0.localizedName < $1.localizedName }), id: \.self) { kind in
                                HStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.cyan)
                                        .frame(width: UIScreen.main.bounds.width * 0.1, height: UIScreen.main.bounds.width * 0.1)
                                        .overlay {
                                            Image(systemName: kind.symbolName)
                                                .foregroundStyle(Color.white)
                                                .font(.title3)
                                        }
                                    Text(kind.localizedName)
                                        .foregroundStyle(Color.primary)
                                }
                            }
                        }, header: {
                            HStack {
                                Text("TODO")
                                    .foregroundStyle(Color.primary)
                                    .font(.headline)
                                    .bold()
                                Spacer()
                                Image(systemName: "ellipsis")
                                    .font(.title2)
                                    .foregroundStyle(Color.gray)
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
