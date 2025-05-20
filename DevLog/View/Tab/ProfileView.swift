//
//  ProfileView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var firebaseVM: FirebaseViewModel
    @FocusState private var focusedOnStatusMsg: Bool
    @State private var showDoneBtn: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        firebaseVM.avatar
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .cornerRadius(30)
                            .foregroundStyle(Color(UIColor.systemGray4))
                        
                        VStack(alignment: .leading) {
                            Text(firebaseVM.name)
                                .font(.title2)
                                .bold()
                            Text(firebaseVM.email)
                                .font(.caption2)
                                .foregroundStyle(Color.gray)
                        }
                    }
                    
                    HStack {
                        HStack {
                            Image(systemName: "face.smiling")
                            TextField(text: $firebaseVM.statusMsg) {
                                HStack {
                                    Text("상태 설정")
                                }
                            }
                            .focused($focusedOnStatusMsg)
                            
                            if !firebaseVM.statusMsg.isEmpty && showDoneBtn {
                                Button(action: {
                                    firebaseVM.statusMsg = ""
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
                                    do {
                                        try await firebaseVM.upsertStatusMsg()
                                    } catch {
                                        
                                    }
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
                        NavigationLink(destination: SettingView()) {
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
        }
    }
}
