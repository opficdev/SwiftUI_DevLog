//
//  Searchable.swift
//  DevLog
//
//  Created by opfic on 5/22/25.
//

import SwiftUI

struct Searchable: View {
    @Environment(\.isSearching) private var isSearching
    @Binding var bindedSearching: Bool

    init(isSearching: Binding<Bool>) {
        self._bindedSearching = isSearching
    }
    
    var body: some View {
        EmptyView()
        .onChange(of: isSearching) { newValue in
            bindedSearching = newValue
        }
    }
}
