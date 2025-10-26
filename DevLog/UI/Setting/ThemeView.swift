//
//  ThemeView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct ThemeView: View {
    @AppStorage("theme") var theme: SystemTheme = .automatic
    @ObservedObject var viewModel: SettingViewModel

    var body: some View {
        List {
            Button(action: {
                theme = .automatic
            }) {
                HStack {
                    Text(SystemTheme.automatic.localizedName)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if theme == .automatic {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: {
                theme = .light
            }) {
                HStack {
                    Text(SystemTheme.light.localizedName)
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
                    Text(SystemTheme.dark.localizedName)
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
        .onChange(of: theme.localizedName) { newValue in
            viewModel.theme = newValue
        }
    }
}

#Preview {
    ThemeView(viewModel: AppContainer.shared.settingViewModel)
}
