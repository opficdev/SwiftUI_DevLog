//
//  SettingView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("theme") var theme: SystemTheme = .automatic
    @AppStorage("appIcon") var appIcon: AppIcon = .primary
    @StateObject private var settingVM = SettingViewModel()
    @EnvironmentObject private var firebaseVM: FirebaseViewModel
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
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
                NavigationLink(destination: AppIconView().environmentObject(settingVM)) {
                    HStack {
                        Text("앱 아이콘")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(settingVM.appIcon)
                            .foregroundStyle(Color.gray)
                    }
                    .onAppear {
                        settingVM.appIcon = appIcon.localizedName
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
                HStack {
                    Text("버전 정보")
                    Spacer()
                    Text(appVersion)
                }
                if let ppurl = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_POLICY_URL") as? String {
                    Link(destination: URL(string: ppurl)!) {
                        Text("개인정보 처리방침")
                            .foregroundColor(Color.blue)
                    }
                }
                Button(action: {
                    if let url = URL(string: "itms-beta://") {
                           UIApplication.shared.open(url, options: [:]) { success in
                               if !success {
                                   if let appStoreURL = URL(string: "https://apps.apple.com/app/testflight/id899247664") {
                                       UIApplication.shared.open(appStoreURL)
                                   }
                               }
                           }
                       }
                }) {
                    VStack(alignment:. leading) {
                        Text("베타 테스트 참여")
                        Text("신규 기능을 빠르게 만나볼 수 있습니다")
                            .foregroundStyle(Color.gray)
                            .font(.caption)
                    }
                }
            }
            
            Section {
                NavigationLink(destination: AccountView().environmentObject(firebaseVM)) {
                    Text("계정 연동")
                }
                Button(role: .destructive, action: {
                    settingVM.signOutAlert = true
                }) {
                    Text("로그아웃")
                }
            }
            
            HStack {
                Spacer()
                Button(role: .destructive, action: {
                    settingVM.deleteUserAlert = true
                }) {
                    Text("회원 탈퇴")
                        .font(.headline)
                }
                Spacer()
            }
        }
        .navigationTitle("설정")
        .alert("로그아웃", isPresented: $settingVM.signOutAlert) {
            Button(role: .cancel, action: {
                settingVM.signOutAlert = false
            }) {
                Text("취소")
            }
            Button(role: .destructive, action: {
                Task {
                    // AppStorage 전체를 삭제하는 코드
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    try await firebaseVM.signOut()
                }
            }) {
                Text("확인")
            }
        } message: {
            Text("로그아웃하시겠습니까?")
        }
        .alert("정말 탈퇴하시겠습니까?", isPresented: $settingVM.deleteUserAlert) {
            Button(role: .cancel, action: {
                settingVM.deleteUserAlert = false
            }) {
                Text("취소")
            }
            Button(role: .destructive, action: {
                Task {
                    // AppStorage 전체를 삭제하는 코드
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    try await firebaseVM.deleteUser()
                }
            }) {
                Text("탈퇴")
            }
        } message: {
            Text("회원 탈퇴가 진행되면 모든 데이터가 지워지고 복구할 수 없습니다.")
        }
    }
}

#Preview {
    SettingView()
}
