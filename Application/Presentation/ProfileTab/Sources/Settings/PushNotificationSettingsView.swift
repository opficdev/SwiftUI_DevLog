//
//  PushNotificationSettingsView.swift
//  ProfileTab
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import PresentationShared

struct PushNotificationSettingsView: View {
    @State var store: StoreOf<PushNotificationSettingsFeature>

    var body: some View {
        List {
            Section(content: {
                HStack {
                    Text(String(localized: "push_settings_enable", bundle: PresentationResources.bundle))
                    Spacer()
                    if store.isLoading && store.activeLoadingRow == .enable {
                        ProgressView()
                    } else {
                        Toggle("", isOn: $store.pushNotificationEnable)
                            .labelsHidden()
                            .tint(.blue)
                            .disabled(store.activeLoadingRow != nil)
                    }
                }
            }, footer: {
                Text(String(localized: "push_settings_footer", bundle: PresentationResources.bundle))
                    .multilineTextAlignment(.leading)
            })
            Section {
                ForEach([9, 15, 18, 21], id: \.self) { hour in
                    if let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
                        let loadingRow = PushNotificationSettingsFeature.activeLoadingRow(for: date)
                        HStack {
                            Text(formattedTimeString(date))
                            Spacer()
                            if let loadingRow,
                               store.isLoading && store.activeLoadingRow == loadingRow {
                                ProgressView()
                            } else if store.activeLoadingRow != loadingRow
                                        && store.pushNotificationHour == hour
                                        && store.pushNotificationMinute == 0 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { store.send(.selectPresetTime(date)) }
                    }
                }
                HStack {
                    Text(String(localized: "push_settings_custom", bundle: PresentationResources.bundle))
                    Spacer()
                    Text(formattedTimeString(store.viewPushNotificationTime))
                        .foregroundStyle(.secondary)
                    if store.pushNotificationMinute != 0 {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { store.send(.tapCustomTime) }
            }
            .disabled(!store.pushNotificationEnable || store.activeLoadingRow != nil)
            .opacity(store.pushNotificationEnable ? 1.0 : 0.2)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "nav_push_settings", bundle: PresentationResources.bundle))
        .onAppear { store.send(.fetchSettings) }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(item: $store.scope(state: \.timePicker, action: \.timePicker)) { timePickerStore in
            TimePickerView(
                store: timePickerStore,
                showsProgressView: store.isLoading && store.activeLoadingRow == .customTime
            )
        }
    }

    private func formattedTimeString(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}

private struct TimePickerView: View {
    @Bindable var store: Store<
        PushNotificationSettingsFeature.TimePickerState,
        PushNotificationSettingsFeature.Action.TimePicker
    >
    let showsProgressView: Bool

    var body: some View {
        NavigationStack {
            DatePicker(
                "",
                selection: $store.time,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onAppear { UIDatePicker.appearance().minuteInterval = 5 }
            .onDisappear { UIDatePicker.appearance().minuteInterval = 1 /* 기본값으로 복원 */ }
            .toolbar {
                ToolbarLeadingButton {
                    store.send(.tapCloseButton)
                }
                if showsProgressView {
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                } else {
                    ToolbarTrailingButton {
                        store.send(.tapDoneButton)
                    }
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        store.send(.binding(.set(\.height, geometry.size.height)))
                    }
                }
            )
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.height(store.height)])
    }
}
