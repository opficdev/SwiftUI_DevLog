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
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray, lineWidth: 1)
                .frame(width: 15, height: 15)
            if isChecked {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

#Preview {
    CheckBox(isChecked: .constant(true))
}
