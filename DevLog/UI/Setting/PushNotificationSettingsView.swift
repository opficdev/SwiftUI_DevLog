//
//  PushNotificationSettingsView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationSettingsView: View {
    @ObservedObject var viewModel: SettingViewModel
    @State private var showTimePicker = false // 시간 선택기 표시 여부
    @State private var sheetHeight: CGFloat = 0 // 시트 높이 조정용
    
    private func hours(from date: Date) -> Int {
       return Calendar.current.component(.hour, from: date)
   }

   var body: some View {
       List {
           Section(content: {
               Toggle(isOn: $viewModel.pushNotificationEnabled, label: {
                   Text("푸시 알람 활성화")
               })
           }, footer: {
               Text("설정에서의 푸시 알람 설정과 별개입니다.")
           })
           Section {
               ForEach([9, 15, 18, 21], id: \.self) { hour in
                   HStack {
                       Text((hour < 12 ? "오전 \(hour)시" : "오후 \(hour - 12)시"))
                       Spacer()
                       if hours(from: viewModel.pushNotificationTime) == hour {
                           Image(systemName: "checkmark")
                               .foregroundStyle(Color.accentColor)
                       }
                   }
                   .contentShape(Rectangle())
                   .onTapGesture {
                       //  시간만 변경
                       if let newDate = Calendar.current.date(
                           bySettingHour: hour,
                           minute: Calendar.current.component(.minute, from: viewModel.pushNotificationTime),
                           second: 0,
                           of: viewModel.pushNotificationTime
                       ) {
                           viewModel.pushNotificationTime = newDate
                       }
                   }
               }
               HStack {
                   Text("사용자 설정")
                   Spacer()
                   Text("\(hours(from: viewModel.pushNotificationTime))시")
                       .foregroundStyle(.secondary)
                   let hour = hours(from: viewModel.pushNotificationTime)
                   if ![9, 15, 18, 21].contains(hour) {
                       Image(systemName: "checkmark")
                           .foregroundStyle(Color.accentColor)
                   }
               }
               .contentShape(Rectangle())
               .onTapGesture {
                   showTimePicker.toggle()
               }
           }
           .disabled(!viewModel.pushNotificationEnabled)
           .opacity(viewModel.pushNotificationEnabled ? 1.0 : 0.2)
       }
       .listStyle(.insetGrouped)
       .navigationTitle("알람")
       .sheet(isPresented: $showTimePicker) {
           DatePicker("",
                      selection: $viewModel.pushNotificationTime,
                      displayedComponents: .hourAndMinute
           )
           .datePickerStyle(.wheel)
           .labelsHidden()
           .presentationDragIndicator(.hidden)
           .presentationDetents([.height(sheetHeight)])
           .onAppear {
               UIDatePicker.appearance().minuteInterval = 5
           }
           .onDisappear {
               UIDatePicker.appearance().minuteInterval = 1 // 기본값으로 복원
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
       }
   }
}

#Preview {
    PushNotificationSettingsView(viewModel: AppContainer.shared.settingViewModel)
}
