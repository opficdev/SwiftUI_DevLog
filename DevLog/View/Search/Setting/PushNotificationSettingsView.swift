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
    @State private var customHour = 9 // 임시, 사용자 설정 시간
    @State private var showTimePicker = false // 시간 선택기 표시 여부
    @State private var sheetHeight: CGFloat = 0 // 시트 높이 조정용
    
    var body: some View {
        List {
            Section(content: {
                Toggle(isOn: $isNotificationEnabled, label: {
                    Text("푸시 알람 활성화")
                })
            }, footer: {
                Text("설정에서의 푸시 알람 설정과 별개입니다.")
            })
            HStack {
                Text("오전 9시")
                Spacer()
            }
            HStack {
                Text("오후 3시")
                Spacer()
            }
            HStack {
                Text("오후 6시")
                Spacer()
            }
            HStack {
                Text("오후 9시")
                Spacer()
            }
            HStack {
                Text("사용자 설정")
                Spacer()
                Text("\(customHour)시")
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        showTimePicker.toggle()
                    }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("알람")
        .sheet(isPresented: $showTimePicker) {
            Picker("사용자 설정", selection: $customHour) {
                ForEach(0..<24) { hour in
                    if hour != 9 && hour != 15 && hour != 18 && hour != 21 {
                        Text("\(hour)시").tag(hour)
                    }
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        if sheetHeight == 0 {
                            sheetHeight = geometry.size.height
                        }
                    }
                }
            )
            .pickerStyle(.wheel)
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(sheetHeight)])
        }
    }
}

#Preview {
    PushNotificationSettingsView()
}
