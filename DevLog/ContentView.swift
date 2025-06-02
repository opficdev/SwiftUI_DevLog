//
//  ContentView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isFirstLaunch") var isFirstLaunch = true   // 앱을 최초 설치했을 때 기존 로그인 세션이 남아있으면 자동 로그인됨을 막음
    @StateObject private var firebaseVM = FirebaseViewModel()
    @StateObject private var networkVM = NetworkViewModel()
    @StateObject private var authService = AuthService()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = firebaseVM.signIn {
                if signIn && !isFirstLaunch {
                    MainView(auth: authService)
                        .environmentObject(firebaseVM)
                }
                else {
                    LoginView()
                        .environmentObject(firebaseVM)
                        .onAppear {
                            if isFirstLaunch {
                                Task {
                                    isFirstLaunch = false
                                }
                            }
                        }
                }
                if firebaseVM.isLoading {
                    LoadingView()
                }
            }
            else {
                Color.clear.onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if firebaseVM.signIn == nil {
                            Task {
                                isFirstLaunch = true
                                try await firebaseVM.signOut()
                            }
                        }
                    }
                }
            }
        }
        .alert("네트워크 문제", isPresented: $networkVM.showNetworkAlert) {
            Button(role: .cancel, action: {
                networkVM.showNetworkAlert = false
            }) {
                Text("확인")
            }
        } message: {
            Text("네트워크 연결을 확인해주세요")
        }
        .onChange(of: isFirstLaunch) { newValue in
            if isFirstLaunch {
                Task {
                    isFirstLaunch = false
                    try await firebaseVM.signOut()
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
