//
//  SearchedView.swift
//  DevLog
//
//  Created by opfic on 5/22/25.
//

import SwiftUI

struct SearchedView: View {
    @Environment(\.isSearching) private var isSearching
    @Binding var searchText: String
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack{
                    if isSearching {
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
                        Text("기본적으로 개발자 문서가 보여지는 곳")
                    }
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: isSearching && searchText.isEmpty ? geometry.size.height : 0)
            }
        }
        
    }
}
