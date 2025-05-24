//
//  SearchView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import LinkPresentation
import UniformTypeIdentifiers

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var isFocused: Bool = false
    @State private var addNewLink: Bool = false
    @State private var newURL: String = "https://"
    @State private var devDocs: [DeveloperDoc] = []
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                SearchedView(searchText: $searchText, focused: $isFocused)
                    .searchable(text: $searchText, prompt: "DevLog 검색")
                GeometryReader { geometry in
                    ScrollView {
                        VStack {
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
                                VStack(alignment: .leading) {
                                    Text("개발자 문서")
                                        .font(.title2)
                                        .bold()
                                    ForEach(devDocs, id: \.id) { doc in
                                        NavigationLink(destination: WebView(url: URL(string: doc.urlString)!)) {
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
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .frame(minHeight: isFocused && searchText.isEmpty ? geometry.size.height : 0)
                    }
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
                                    if let url = URL(string: newURL) {
                                        let provider = LPMetadataProvider()
                                        let metadata = try await provider.startFetchingMetadata(for: url)
                                        
                                        let uiImage = try await convertToImage(metadata)
                                        let title = metadata.title ?? ""
                                        let urlString = metadata.url?.host() ?? newURL

                                        let newDoc = DeveloperDoc(title, urlString: urlString, uiImage: uiImage)
                                        devDocs.append(newDoc)
                                    }
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
    
    private func convertToImage(_ metaData: LPLinkMetadata) async throws -> UIImage? {
        let imageType = UTType.image.identifier

        if let imageProvider = metaData.imageProvider,
            imageProvider.hasItemConformingToTypeIdentifier(imageType) {
            let imageItem = try await imageProvider.loadItem(forTypeIdentifier: imageType)
            
            switch imageItem {
            case let uiImage as UIImage:
                return uiImage
                
            case let url as URL:
                if let data = try? Data(contentsOf: url) {
                    return UIImage(data: data)
                }
                
            case let data as Data:
                return UIImage(data: data)
                
            case let nsData as NSData:
                return UIImage(data: nsData as Data)
                
            default:
                return nil
            }
        }
        return nil
    }
}
