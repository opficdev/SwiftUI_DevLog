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
    @EnvironmentObject private var firebaseVM: FirebaseViewModel
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: ThemeView().environmentObject(settingVM)) {
                    HStack {
                        Text("테마")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(settingVM.theme)
                            .foregroundStyle(Color.gray)
                    }
                    .onAppear {
                        settingVM.theme = theme.localizedName
                    }
                }
                NavigationLink(destination: AppIconView()) {
                    HStack {
                        Text("앱 아이콘")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(settingVM.appIcon)
                            .foregroundStyle(Color.gray)
                    }
                    .onAppear {
                        
                    }
                }
                NavigationLink(destination: AlertView()) {
                    HStack {
                        Text("알림")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(settingVM.notification)
                            .foregroundStyle(Color.gray)
                    }
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    settingVM.logoutAlert = true
                }) {
                    Text("로그아웃")
                }
            }
        }
        .navigationTitle("설정")
        .alert("로그아웃", isPresented: $settingVM.logoutAlert) {
            Button(role: .cancel, action: {
                settingVM.logoutAlert = false
            }) {
                Text("취소")
            }
            Button(role: .destructive, action: {
                Task {
                    try await firebaseVM.signOut()
                }
            }) {
                Text("확인")
            }
        } message: {
            Text("로그아웃하시겠습니까?")
        }
    }
}

#Preview {
    SettingView()
}
