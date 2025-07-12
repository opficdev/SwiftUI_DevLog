//
//  PushNotificationSettingsView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationSettingsView: View {
    @EnvironmentObject var settingVM: SettingViewModel
    @State private var isNotificationEnabled: Bool = true // 임시
    
    var body: some View {
        List {
            Section(content: {
                Toggle(isOn: $isNotificationEnabled, label: {
                    Text("푸시 알람 활성화")
                })
            }, footer: {
                Text("설정에서의 푸시 알람 설정과 별개입니다.")
            })
        }
        .listStyle(.insetGrouped)
        .navigationTitle("푸시 알람 설정")
    }
}

#Preview {
    PushNotificationSettingsView()
}
