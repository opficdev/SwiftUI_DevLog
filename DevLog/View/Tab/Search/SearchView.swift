//
//  SearchView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseVM: FirebaseViewModel
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var addNewLink: Bool = false
    @State private var newURL: String = "https://"
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var selectedDoc: DeveloperDoc? = nil
    
    var body: some View {
        NavigationStack {
            SearchableView(searchText: $searchText, focused: $isSearching)
                .searchable(text: $searchText, prompt: "DevLog 검색")
                .navigationDestination(isPresented: Binding(
                    get: { selectedDoc != nil },
                    set: { if !$0 { selectedDoc = nil } }
                )) {
                    if let url = selectedDoc?.url {
                        WebView(url: url)
                            .navigationBarTitleDisplayMode(.inline) //  이렇게 명시해주지 않으면 iOS 18 미만에서는 Large 크기만큼의 상단의 영역을 어느정도 먹고있음
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(selectedDoc!.title)
                                        .bold()
                                }
                            }
                    }
                }
            GeometryReader { geometry in
                List {
                    if isSearching {
                        if searchText.isEmpty {
                            VStack {
                                Spacer()
                                Text("앱 내 컨텐츠를 검색할 수 있어요.")
                                Spacer()
                            }
                            .frame(height: geometry.size.height)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        else {
                            Text("검색 내용이 보여지는 곳")
                        }
                    }
                    else {
                        Section {
                            ForEach(Array(zip(firebaseVM.devDocs.indices, firebaseVM.devDocs)), id: \.1.id) { idx, doc in
                                Button(action: {
                                    selectedDoc = doc
                                }) {
                                    ZStack(alignment: .bottom) {
                                        Color.white
                                        if let uiImage = doc.image {
                                            GeometryReader { geo in
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: geo.size.width, height: geo.size.height)
                                                    .clipped()
                                            }
                                        }
                                        else {
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
                                                Text(doc.title)
                                                    .foregroundStyle(Color.black)
                                                    .multilineTextAlignment(.leading)
                                                Text(doc.urlString)
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
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            Task {
                                                do {
                                                    firebaseVM.devDocs.remove(at: idx)
                                                    try await firebaseVM.deleteDevDoc(doc)
                                                } catch {
                                                    errorMessage = "웹페이지를 추가하던 중 오류가 발생했습니다."
                                                    showError = true
                                                }
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
                            addNewLink = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .alert("", isPresented: $showError) {
                    Button("확인", role: .cancel) {
                        errorMessage = ""
                    }
                } message: {
                    Text(errorMessage)
                }
                .alert("개발자 문서 추가", isPresented: $addNewLink) {
                    TextField("URL", text: $newURL)
                    HStack {
                        Button(action: {
                            newURL = "https://"
                            dismiss()
                        }) {
                            Text("취소")
                        }
                        Button(action: {
                            Task {
                                let newDoc = try await DeveloperDoc.fetch(from: newURL)
                                try await firebaseVM.upsertDevDoc(newDoc, urlString: newURL)
                                firebaseVM.devDocs.append(newDoc)
                                newURL = "https://"
                                dismiss()
                            }
                        }) {
                            Text("추가")
                        }
                    }
                }
            }
        }
    }
}
