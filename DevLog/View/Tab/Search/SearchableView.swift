//
//  SearchableView.swift
//  DevLog
//
//  Created by opfic on 5/22/25.
//

import SwiftUI

struct SearchableView: View {
    @Environment(\.isSearching) private var is_searching
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    var body: some View {
        EmptyView()
        .onChange(of: is_searching) { newValue in
            isSearching = newValue
        }
    }
}
