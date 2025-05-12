//
//  LoginView.swift
//  SnapPlan
//
//  Created by opfic on 12/30/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var firebaseVM: FirebaseViewModel
    @Environment(\.colorScheme) var colorScheme
    
    let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Group {
//                    if colorScheme == .light {
                        Image("DevLog")
                            .resizable()
//                    }
//                    else {
//                        Image("dark_logo")
//                            .resizable()
//                    }
                }
                .scaledToFit()
                .frame(width: screenWidth / 5)
                Spacer()
                VStack(spacing: 20) {
                    LoginButton(logo: Image("Google"), text: "구글 계정으로 로그인") {
                        if firebaseVM.isConnected {
                            Task {
                                do {
                                    try await firebaseVM.signInWithGoogle()
                                } catch {
                                    
                                }
                            }
                        }
                        else {
                            firebaseVM.showNetworkAlert = true
                        }
                    }
                    .frame(width: screenWidth * 3 / 4, height: screenWidth / 10)
                    
                    LoginButton(logo: Image("Github"), text: "깃헙 계정으로 로그인") {
                        if firebaseVM.isConnected {
                            Task {
                                do {
                                    try await firebaseVM.signInWithGithub()
                                } catch {
                                    
                                }
                            }
                        }
                        else {
                            firebaseVM.showNetworkAlert = true
                        }
                    }
                    .frame(width: screenWidth * 3 / 4, height: screenWidth / 10)
                        
                    LoginButton(logo: Image("Apple"), text: "애플 계정으로 로그인") {
                        if firebaseVM.isConnected {
                            Task {
                                do {
                                    try await firebaseVM.signInWithApple()
                                } catch {
                                    
                                }
                            }
                        }
                        else {
                            firebaseVM.showNetworkAlert = true
                        }
                    }
                    .frame(width: screenWidth * 3 / 4, height: screenWidth / 10)
                }
                .padding(.bottom, 30)
                Text("로그인하면 사용 약관 및 개인 정보 취급 방침에 동의하게 됩니다.")
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
            }
        }
    }
}

#Preview {
    LoginView()
}
