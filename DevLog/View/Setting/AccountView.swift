//
//  AccountView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var connectedProviders: [String] = []
    @State private var disconnectedProviders: [String] = []
    
    var body: some View {
        List {
            Section("현재 계정") {
                HStack {
                    // provider에서 첫번째 글자만 대문자로 바꾸고 .을 포함한 뒤는 다 제거 ex) google.com -> Google
                    let formattedProvider = profileVM.currentProvider.prefix(1).uppercased() + profileVM.currentProvider.dropFirst().prefix(while: { $0 != "." })
                    Image(formattedProvider)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIFont.labelFontSize)
                    Text(formattedProvider)
                }
            }
            Section("연동된 계정") {
                ForEach(connectedProviders, id: \.self) { provider in
                    HStack {
                        let formattedProvider = provider.prefix(1).uppercased() + provider.dropFirst().prefix(while: { $0 != "." })
                        Image(formattedProvider)
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIFont.labelFontSize)
                        Text(formattedProvider)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive, action: {
                            Task {
                                await profileVM.unlinkFromProvider(provider: provider)
                            }
                        }) {
                            Label("계정 삭제", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .onAppear {
            connectedProviders = profileVM.providers.filter { provider in
                provider != profileVM.currentProvider
            }
            disconnectedProviders = ["google.com", "github.com", "apple.com"].filter { provider in
                !profileVM.providers.contains(provider)
            }
        }
        .onChange(of: profileVM.providers) { newProviders in
            connectedProviders = newProviders.filter { provider in
                provider != profileVM.currentProvider
            }
            disconnectedProviders = ["google.com", "github.com", "apple.com"].filter { provider in
                !newProviders.contains(provider)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("계정 연동")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu("새 계정 연동", systemImage: "plus") {
                    ForEach(disconnectedProviders, id: \.self) { provider in
                        Button(action: {
                            Task {
                                await profileVM.linkWithProvider(provider: provider)
                            }
                        }) {
                            HStack {
                                let formattedProvider = provider.prefix(1).uppercased() + provider.dropFirst().prefix(while: { $0 != "." })
                                Image(formattedProvider)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: UIFont.systemFontSize, height: UIFont.systemFontSize)
                                Text(formattedProvider)
                            }
                        }
                    }
                }
            }
        }
        .alert("계정 연동 실패", isPresented: $profileVM.showAccountAlert) {
            Button("확인", role: .cancel) {
                profileVM.showAccountAlert = false
            }
        } message: {
            Text(profileVM.alertMsg)
        }
    }
}

#Preview {
    AccountView()
}
