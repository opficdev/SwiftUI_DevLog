//
//  ProfileView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var container: AppContainer  //  settingVM을 주입하기 위함
    @StateObject private var profileVM: ProfileViewModel
    @FocusState private var focusedOnStatusMsg: Bool
    @State private var showDoneBtn: Bool = false

    init(container: AppContainer) {
        self._profileVM = StateObject(wrappedValue: container.profileVM)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        profileVM.avatar
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .cornerRadius(30)
                            .foregroundStyle(Color.gray)
                        
                        VStack(alignment: .leading) {
                            Text(profileVM.name)
                                .font(.title2)
                                .bold()
                            Text(profileVM.email)
                                .font(.caption2)
                                .foregroundStyle(Color.gray)
                        }
                    }
                    
                    HStack {
                        HStack {
                            Image(systemName: "face.smiling")
                            TextField(text: $profileVM.statusMsg) {
                                HStack {
                                    Text("상태 설정")
                                }
                            }
                            .focused($focusedOnStatusMsg)
                            
                            if !profileVM.statusMsg.isEmpty && showDoneBtn {
                                Button(action: {
                                    profileVM.statusMsg = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .foregroundStyle(Color.gray)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemGray5))
                        )
                        if showDoneBtn {
                            Button(action: {
                                focusedOnStatusMsg = false
                                Task {
                                    await profileVM.upsertStatusMsg()
                                }
                            }) {
                                Text("완료")
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 0) {
                        NavigationLink(destination: SettingView(settingVM: container.settingVM)) {
                            Image(systemName: "gearshape")
                        }
                        Button(action: {
                            
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .onChange(of: focusedOnStatusMsg) { newValue in
                withAnimation {
                    showDoneBtn = newValue
                }
            }
            .alert("", isPresented: $profileVM.showProfileAlert) {
                Button("확인") {
                    profileVM.showProfileAlert = false
                }
            } message: {
                Text(profileVM.alertMsg)
            }
        }
    }
}
