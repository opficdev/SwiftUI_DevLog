//
//  CheckBox.swift
//  DevLog
//
//  Created by opfic on 6/17/25.
//

import SwiftUI

struct CheckBox: View {
    @Binding var isChecked: Bool
    
    var body: some View {
        Group {
            if isChecked {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.accentColor)
            }
            else {
                Image(systemName: "circle")
                    .foregroundStyle(Color.gray)
            }
        }
        .font(.title2)
    }
}

#Preview {
    CheckBox(isChecked: .constant(true))
}
