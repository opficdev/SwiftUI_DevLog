//
//  SearchView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            SearchedView(searchText: $searchText)
                .searchable(text: $searchText, prompt: "DevLog 검색")
                .navigationTitle("검색")
        }
    }
}
