//
//  Searchable.swift
//  DevLog
//
//  Created by opfic on 5/22/25.
//

import SwiftUI

struct Searchable: View {
    @Environment(\.isSearching) private var is_searching
    @Binding var isSearching: Bool
    
    var body: some View {
        EmptyView()
        .onChange(of: is_searching) { newValue in
            isSearching = newValue
        }
    }
}
