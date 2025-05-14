//
//  ContentView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @StateObject var firebaseVM = FirebaseViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = firebaseVM.signIn {
                if signIn && !isFirstLaunch {
                    MainView()
                        .environmentObject(firebaseVM)
                }
                else {
                    LoginView()
                        .environmentObject(firebaseVM)
                        .onAppear {
                            if isFirstLaunch {
                                Task {
                                    try await firebaseVM.signOut()
                                    isFirstLaunch = false
                                }
                            }
                        }
                }
            }
            else {
                Color.clear.onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if firebaseVM.signIn == nil {
                            Task {
                                try await firebaseVM.signOut()
                                isFirstLaunch = true
                            }
                        }
                    }
                }
            }
        }
        .alert("네트워크 문제", isPresented: $firebaseVM.showNetworkAlert) {
            Button(role: .cancel, action: {
                firebaseVM.showNetworkAlert = false
            }) {
                Text("확인")
            }
        } message: {
            Text("네트워크 연결을 확인해주세요")
        }
    }
}


#Preview {
    ContentView()
}
