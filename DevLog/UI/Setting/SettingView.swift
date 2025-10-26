//
//  SettingView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("theme") var theme: SystemTheme = .automatic
    @ObservedObject var viewModel: SettingViewModel
    @State private var signOutAlert = false
    @State private var deleteUserAlert = false
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    var body: some View {
        Form {
            Section {
                NavigationLink(destination: ThemeView(viewModel: viewModel)) {
                    HStack {
                        Text("테마")
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Text(viewModel.theme)
                            .foregroundStyle(Color.gray)
                    }
                    .onAppear {
                        viewModel.theme = theme.localizedName
                    }
                }
                NavigationLink(destination: PushNotificationSettingsView(viewModel: viewModel)) {
                    Text("알림")
                        .foregroundStyle(Color.primary)
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
                                   if let urlString = Bundle.main.object(
                                    forInfoDictionaryKey: "APPSTORE_URL") as? String,
                                      let appStoreURL = URL(string: urlString) {
                                       UIApplication.shared.open(appStoreURL)
                                   }
                               }
                           }
                       }
                }) {
                    VStack(alignment: .leading) {
                        Text("베타 테스트 참여")
                        Text("신규 기능을 빠르게 만나볼 수 있습니다")
                            .foregroundStyle(Color.gray)
                            .font(.caption)
                    }
                }
            }
            
            Section {
                NavigationLink(destination: AccountView(viewModel: viewModel)) {
                    Text("계정 연동")
                }
                Button(role: .destructive, action: {
                    signOutAlert = true
                }) {
                    Text("로그아웃")
                }
            }
            
            HStack {
                Spacer()
                Button(role: .destructive, action: {
                    deleteUserAlert = true
                }) {
                    Text("회원 탈퇴")
                        .font(.headline)
                }
                Spacer()
            }
        }
        .navigationTitle("설정")
        .alert("로그아웃", isPresented: $signOutAlert) {
            Button(role: .cancel, action: {
                signOutAlert = false
            }) {
                Text("취소")
            }
            Button(role: .destructive, action: {
                Task {
                    await viewModel.signOut()
                }
            }) {
                Text("확인")
            }
        } message: {
            Text("로그아웃하시겠습니까?")
        }
        .alert("정말 탈퇴하시겠습니까?", isPresented: $deleteUserAlert) {
            Button(role: .cancel, action: {
                deleteUserAlert = false
            }) {
                Text("취소")
            }
            Button(role: .destructive, action: {
                Task {
                    await viewModel.deleteAuth()
                }
            }) {
                Text("탈퇴")
            }
        } message: {
            Text("회원 탈퇴가 진행되면 모든 데이터가 지워지고 복구할 수 없습니다.")
        }
        .alert("", isPresented: $viewModel.showAlert) {
            Button(role: .cancel, action: {
                viewModel.showAlert = false
            }) {
                Text("확인")
            }
        } message: {
            Text(viewModel.alertMsg)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
    }
}
