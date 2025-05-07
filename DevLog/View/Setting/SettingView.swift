//
//  SettingView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: ThemeView()) {
                    HStack {
                        Text("테마")
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingView()
}
