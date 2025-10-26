//
//  NotificationView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct NotificationView: View {
    @ObservedObject private var notiVM: NotificationViewModel

    init(notiVM: NotificationViewModel) {
        self._notiVM = ObservedObject(wrappedValue: notiVM)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if notiVM.notifications.isEmpty {
                    Spacer()
                    Text("작성된 알림이 없습니다.")
                        .foregroundStyle(Color.gray)
                    Spacer()
                }
                else {
                    List(notiVM.notifications) { noti in
                        if let notiId = noti.id {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(noti.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(noti.body)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 5)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive, action: {
                                    Task {
                                        await notiVM.deleteNotification(notificationId: notiId)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(UIColor.secondarySystemBackground))
            .navigationTitle("받은 푸시 알람")
            .alert("", isPresented: $notiVM.showAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(notiVM.alertMsg)
            }
            .onAppear {
                Task {
                    await notiVM.requestNotifications()
                }
            }
        }
    }
}

#Preview {
    NotificationView(notiVM: AppContainer.shared.notiVM)
}
