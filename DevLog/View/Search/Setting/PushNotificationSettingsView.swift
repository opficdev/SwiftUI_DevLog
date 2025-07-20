//
//  PushNotificationSettingsView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationSettingsView: View {
    @EnvironmentObject var settingVM: SettingViewModel
    @State private var showTimePicker = false // 시간 선택기 표시 여부
    @State private var sheetHeight: CGFloat = 0 // 시트 높이 조정용
    
    var body: some View {
        List {
            Section(content: {
                Toggle(isOn: $settingVM.pushNotificationEnabled, label: {
                    Text("푸시 알람 활성화")
                })
            }, footer: {
                Text("설정에서의 푸시 알람 설정과 별개입니다.")
            })
            Section {
                HStack {
                    Text("오전 9시")
                    Spacer()
                    if settingVM.pushNotificationHour == 9 {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    settingVM.pushNotificationHour = 9
                }
                HStack {
                    Text("오후 3시")
                    Spacer()
                    if settingVM.pushNotificationHour == 15 {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
                
                .onTapGesture {
                    settingVM.pushNotificationHour = 15
                }
                HStack {
                    Text("오후 6시")
                    Spacer()
                    if settingVM.pushNotificationHour == 18 {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    settingVM.pushNotificationHour = 18
                }
                HStack {
                    Text("오후 9시")
                    Spacer()
                    if settingVM.pushNotificationHour == 21 {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    settingVM.pushNotificationHour = 21
                }
                HStack {
                    Text("사용자 설정")
                    Spacer()
                    Text("\(settingVM.pushNotificationHour)시")
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            showTimePicker.toggle()
                        }
                }
            }
            .disabled(!settingVM.pushNotificationEnabled)
            .opacity(settingVM.pushNotificationEnabled ? 1.0 : 0.2)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("알람")
        .sheet(isPresented: $showTimePicker) {
            Picker("사용자 설정", selection: $settingVM.pushNotificationHour) {
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
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(sheetHeight)])
        }
    }
}

#Preview {
    PushNotificationSettingsView()
}
