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
    @State private var isFocused: Bool = false
    @State private var addNewLink: Bool = false
    @State private var newURL: String = "https://"
    
    var body: some View {
        NavigationStack {
            SearchableView(searchText: $searchText, focused: $isFocused)
                .searchable(text: $searchText, prompt: "DevLog 검색")
            List {
                if isFocused {
                    if searchText.isEmpty {
                        Text("앱 내 컨텐츠나 개발자 문서를 검색할 수 있어요.")
                    }
                    else {
                        Text("검색 내용이 보여지는 곳")
                    }
                }
                else {
                    Section(header: Text("개발자 문서").foregroundStyle(Color.primary).font(.title2).bold()) {
                        ForEach(Array(zip(firebaseVM.devDocs.indices, firebaseVM.devDocs)), id: \.1.id) { idx, doc in
                            NavigationLink(destination: WebView(url: doc.url)) {
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
                                        firebaseVM.devDocs.remove(at: idx)
                                        try await firebaseVM.deleteDevDoc(doc)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)  //  개발자 문서 섹션의 구분선 숨김
                    .listSectionSeparator(.hidden)  //  개발자 문서 섹션의 구분선 숨김
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .navigationTitle("검색")
            .onSubmit(of: .search) {
                isFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        addNewLink = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
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
