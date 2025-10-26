//
//  SearchView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var searchVM: SearchViewModel

    init(searchVM: SearchViewModel) {
        self._searchVM = ObservedObject(wrappedValue: searchVM)
    }
    
    var body: some View {
        NavigationStack {
            // MARK: - 상단 검색바
            Searchable(isSearching: $searchVM.isSearching)
                .searchable(text: $searchVM.searchText, prompt: "DevLog 검색")
                .navigationDestination(isPresented: Binding(
                    get: { searchVM.selectedWebPage != nil },
                    set: { if !$0 { searchVM.selectedWebPage = nil } }
                )) {
                    if let url = searchVM.selectedWebPage?.url {
                        WebView(url: url)
                            .navigationBarTitleDisplayMode(.inline) //  명시하지 않으면 iOS 18 미만에서는 Large 크기만큼의 상단의 영역을 차지
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(searchVM.selectedWebPage!.title)
                                        .bold()
                                }
                            }
                    }
                }
            GeometryReader { geometry in
                List {
                    if searchVM.isSearching {
                        if searchVM.searchText.isEmpty {
                            VStack {
                                Spacer()
                                Text("앱 내 컨텐츠를 검색할 수 있어요.")
                                    .foregroundStyle(Color.gray)
                                Spacer()
                            }
                            .frame(height: geometry.size.height)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        } else {
                            let webPages = searchVM.webPages.filter {
                                $0.title.localizedCaseInsensitiveContains(searchVM.searchText) ||
                                $0.urlString.localizedCaseInsensitiveContains(searchVM.searchText)
                            }
                            if !webPages.isEmpty {
                                ForEach(webPages, id: \.id) { page in
                                    Button(action: {
                                        searchVM.selectedWebPage = page
                                    }) {
                                        HStack {
                                            Group {
                                                if let uiImage = page.image {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                } else {
                                                    Image(systemName: "globe")
                                                        .resizable()
                                                        .scaledToFit()
                                                }
                                            }
                                            .frame(
                                                width: UIScreen.main.bounds.width / 5,
                                                height: UIScreen.main.bounds.width / 5
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            
                                            VStack(alignment: .leading) {
                                                Text(page.title)
                                                    .foregroundStyle(Color.primary)
                                                    .bold()
                                                Text(page.urlString)
                                                    .foregroundStyle(Color.accentColor)
                                                    .underline()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            if searchVM.webPages.isEmpty {
                                Text("저장된 웹페이지가 없습니다.\n우측 '+' 버튼을 눌러 웹페이지를 추가해보세요.")
                                    .foregroundStyle(Color.gray)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: geometry.size.height)
                                    .multilineTextAlignment(.center)
                            } else {
                                let webPages = searchVM.webPages
                                ForEach(Array(zip(webPages.indices, webPages)), id: \.1.id) { idx, page in
                                    Button(action: {
                                        searchVM.selectedWebPage = page
                                    }) {
                                        ZStack(alignment: .bottom) {
                                            Color.white
                                            if let uiImage = page.image {
                                                GeometryReader { geo in
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: geo.size.width, height: geo.size.height)
                                                        .clipped()
                                                }
                                            } else {
                                                VStack {
                                                    Image(systemName: "globe")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: UIScreen.main.bounds.height / 5)
                                                        .foregroundStyle(Color.gray)
                                                        .padding()
                                                    Spacer()
                                                }
                                            }
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(page.title)
                                                        .foregroundStyle(Color.black)
                                                        .multilineTextAlignment(.leading)
                                                    Text(page.urlString)
                                                        .foregroundStyle(Color.accentColor)
                                                        .underline()
                                                }
                                                .padding()
                                                Spacer()
                                            }
                                            .background(Color.white)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                        .frame(height: UIScreen.main.bounds.height / 4)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            Task {
                                                await searchVM.deleteWebPage(webPage: page)
                                                searchVM.webPages.remove(at: idx)
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .listRowSeparator(.hidden)  //  섹션 내 요소의 구분선 숨김
                        .listSectionSeparator(.hidden)  //  섹션의 구분선 숨김
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("검색")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            searchVM.addNewLink = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .alert("", isPresented: $searchVM.showAlert) {
                    Button("확인", role: .cancel) {
                        searchVM.alertMsg = ""
                    }
                } message: {
                    Text(searchVM.alertMsg)
                }
                .alert("웹페이지 추가", isPresented: $searchVM.addNewLink) {
                    TextField("URL", text: $searchVM.newURL)
                    HStack {
                        Button(action: {
                            searchVM.newURL = "https://"
                            dismiss()
                        }) {
                            Text("취소")
                        }
                        Button(action: {
                            Task {
                                let newPage = try await WebPageInfo.fetch(from: searchVM.newURL)
                                await searchVM.upsertWebPage(webPage: newPage)
                                searchVM.webPages.append(newPage)
                                searchVM.newURL = "https://"
                                dismiss()
                            }
                        }) {
                            Text("추가")
                        }
                    }
                }
                .overlay {
                    if searchVM.isLoading {
                        LoadingView()
                    }
                }
            }
        }
    }
}
