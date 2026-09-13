//
//  CheckBox.swift
//  HomeTab
//
//  Created by opfic on 6/17/25.
//

import SwiftUI

struct CheckBox: View {
    private let isChecked: Bool
    @State private var font: Font
    
    init(isChecked: Bool, font: Font = .title2) {
        self.isChecked = isChecked
        self._font = State(initialValue: font)
    }
    
    var body: some View {
        Group {
            if isChecked {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(Color.gray)
            }
        }
        .font(font)
    }
}

#Preview {
    CheckBox(isChecked: true)
}
