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
    @Binding var focused: Bool
    
    var body: some View {
        EmptyView()
        .onChange(of: isSearching) { newValue in
            focused = newValue
        }
    }
}
