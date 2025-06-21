//
//  HomeView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject private var homeVM: HomeViewModel
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var reorderTodo: Bool = false
    
    init(container: AppContainer) {
        self._homeVM = StateObject(wrappedValue: container.homeVM)
    }
        
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack {
                    Searchable(isSearching: $isSearching)
                        .searchable(text: $searchText, prompt: "DevLog 검색")
                    List {
                        Section(content: {
                            ForEach(homeVM.selectedTodoKinds, id: \.self) { kind in
                                NavigationLink(destination: TodoView(todoVM: container.todoVM(kind: kind))) {
                                    HStack {
                                        let width = UIScreen.main.bounds.width * 0.08
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(kind.color)
                                            .frame(width: width, height: width)
                                            .overlay {
                                                Image(systemName: kind.symbolName)
                                                    .foregroundStyle(Color.white)
                                                    .font(.title3)
                                            }
                                        Text(kind.localizedName)
                                            .foregroundStyle(Color.primary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }, header: {
                            HStack {
                                Text("TODO")
                                    .foregroundStyle(Color.primary)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                Button(action: {
                                    reorderTodo = true
                                }) {
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundStyle(Color.gray)
                                }
                            }
                            .listRowInsets(EdgeInsets())    //  헤더의 padding 제거
                        })
                        
                        Section(content: {
                            if homeVM.pinnedTodos.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("최근에 중요 표시를 한 Todo가 여기 표시됩니다.")
                                    Spacer()
                                }
                            }
                            else {
                                
                            }
                        }, header: {
                            HStack {
                                Text("중요 표시")
                                    .foregroundStyle(Color.primary)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                
                            }
                            .listRowInsets(EdgeInsets())
                        })
                    }
                }
            }
            .navigationTitle("홈")
            .sheet(isPresented: $reorderTodo) {
                TodoManageView().environmentObject(container.homeVM)
            }
        }
    }
}
