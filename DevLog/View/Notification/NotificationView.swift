//
//  NotificationView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var notiVM: NotificationViewModel
    
    init(notiVM: NotificationViewModel) {
        self._notiVM = StateObject(wrappedValue: notiVM)
    }
    
    var body: some View {
        NavigationStack {
            List(notiVM.notifications) { noti in
                
                
            }
            .listStyle(.plain)
            .navigationTitle("알림")
            .alert("", isPresented: $notiVM.showAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(notiVM.alertMsg)
            }
        }
    }
}

#Preview {
    NotificationView(notiVM: AppContainer.shared.notiVM)
}
