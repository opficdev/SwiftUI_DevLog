//
//  ThemeView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct ThemeView: View {
    @AppStorage("theme") var theme: SystemTheme = .automatic
    
    var body: some View {
        List {
            Button(action: {
                theme = .automatic
            }) {
                HStack {
                    Text("자동")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if  theme == .automatic {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: {
                theme = .light
            }) {
                HStack {
                    Text("라이트 모드")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if theme == .light {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: {
                theme = .dark
            }) {
                HStack {
                    Text("다크 모드")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if theme == .dark {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("테마")
                    .bold()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ThemeView()
}
