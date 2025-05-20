//
//  AccountView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @EnvironmentObject var firebaseVM: FirebaseViewModel
    @State private var isShowingAlert = false
    @State private var connectedProviders: [String] = []
    @State private var disconnectedProviders: [String] = []
    
    var body: some View {
        List {
            Section {
                HStack {
                    // provider에서 첫번째 글자만 대문자로 바꾸고 .을 포함한 뒤는 다 제거 ex) google.com -> Google
                    let formattedProvider = firebaseVM.currentProvider.prefix(1).uppercased() + firebaseVM.currentProvider.dropFirst().prefix(while: { $0 != "." })
                    Image(formattedProvider)
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIFont.labelFontSize)
                    Text(formattedProvider)
                }
            }
            Section {
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
                                do {
                                    try await firebaseVM.unlinkWithProviders(provider: provider)
                                } catch {
                                    isShowingAlert = true
                                }
                            }
                        }) {
                            Label("계정 삭제", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .onAppear {
            connectedProviders = firebaseVM.providers.filter { provider in
                provider != firebaseVM.currentProvider
            }
            disconnectedProviders = ["google.com", "github.com", "apple.com"].filter { provider in
                !firebaseVM.providers.contains(provider)
            }
        }
        .onChange(of: firebaseVM.providers) { newProviders in
            connectedProviders = newProviders.filter { provider in
                provider != firebaseVM.currentProvider
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
                                do {
                                    try await firebaseVM.linkWithProviders(provider: provider)
                                } catch {
                                    isShowingAlert = true
                                }
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
        .alert("계정 삭제 실패", isPresented: $isShowingAlert) {
            Button("확인", role: .cancel) {
                isShowingAlert = false
            }
        } message: {
            Text(alertMsg)
        }
    }
}

#Preview {
    AccountView()
}
