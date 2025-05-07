//
//  SettingView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("theme") var theme: SystemTheme = .automatic
    @StateObject private var settingVM = SettingViewModel()
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: ThemeView().environmentObject(settingVM)) {
                    HStack {
                        Text("테마")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text("\(settingVM.theme)")
                            .foregroundStyle(Color.gray)
                    }
                    .onAppear {
                        settingVM.theme = theme.localizedName
                    }
                }
            }
        }
        .navigationTitle("설정")
    }
}

#Preview {
    SettingView()
}
