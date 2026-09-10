//
//  PushNotificationSettingsFeature.swift
//  ProfileTab
//
//  Created by opfic on 6/12/26.
//

import Domain
import Foundation
import PresentationShared
import SwiftUI

@Reducer
struct PushNotificationSettingsFeature {
    enum ActiveLoadingRow: Equatable {
        case enable
        case presetTime(hour: Int, minute: Int)
        case customTime
    }

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        @Presents var timePicker: TimePickerState?
        var pushNotificationEnable = false
        var viewPushNotificationTime = Date()
        var activeLoadingRow: ActiveLoadingRow?
        var loading = LoadingFeature.State()

        var isLoading: Bool {
            loading.isLoading
        }
        var pushNotificationHour: Int {
            Calendar.current.component(.hour, from: viewPushNotificationTime)
        }
        var pushNotificationMinute: Int {
            Calendar.current.component(.minute, from: viewPushNotificationTime)
        }
    }

    @ObservableState
    struct TimePickerState: Equatable {
        var time: Date
        var height: CGFloat = .pi
    }

    enum Action: BindableAction {
        case alert(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case timePicker(PresentationAction<TimePicker>)
        case fetchSettings
        case applyFetchedSettings(PushNotificationSettings)
        case setAlert
        case tapCustomTime
        case selectPresetTime(Date)
        case clearActiveLoadingRow
        case loading(LoadingFeature.Action)

        enum TimePicker: BindableAction, Equatable {
            case binding(BindingAction<TimePickerState>)
            case tapCloseButton
            case tapDoneButton
        }
    }

    @Dependency(\.fetchPushSettingsUseCase) var fetchPushSettingsUseCase
    @Dependency(\.updatePushSettingsUseCase) var updatePushSettingsUseCase

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .binding(\.pushNotificationEnable):
                state.activeLoadingRow = .enable
                return updatePushNotificationSettingsEffect(settings: Self.settings(from: state))
            case .binding(\.viewPushNotificationTime):
                let time = state.viewPushNotificationTime
                state.timePicker?.time = time
            case .binding:
                break
            case .timePicker(.dismiss):
                state.timePicker = nil
            case .timePicker(.presented(.tapCloseButton)):
                state.timePicker = nil
            case .timePicker(.presented(.tapDoneButton)):
                guard let time = state.timePicker?.time else { break }
                state.viewPushNotificationTime = time
                state.activeLoadingRow = .customTime
                return updatePushNotificationSettingsEffect(
                    settings: Self.settings(from: state),
                    dismissesTimePickerOnSuccess: true
                )
            case .timePicker:
                break
            case .fetchSettings:
                state.activeLoadingRow = .enable
                return fetchPushNotificationSettingsEffect()
            case .applyFetchedSettings(let settings):
                state.pushNotificationEnable = settings.isEnabled
                if let hour = settings.scheduledTime.hour,
                   let minute = settings.scheduledTime.minute,
                   let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                    state.viewPushNotificationTime = date
                }
            case .setAlert:
                state.alert = Self.alertState()
            case .tapCustomTime:
                state.timePicker = TimePickerState(time: state.viewPushNotificationTime)
            case .selectPresetTime(let date):
                state.viewPushNotificationTime = date
                state.timePicker?.time = date
                state.activeLoadingRow = Self.activeLoadingRow(for: date)
                return updatePushNotificationSettingsEffect(settings: Self.settings(from: state))
            case .clearActiveLoadingRow:
                state.activeLoadingRow = nil
            case .loading:
                break
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$timePicker, action: \.timePicker) {
            TimePickerFeature()
        }
    }
}

private struct TimePickerFeature: Reducer {
    typealias State = PushNotificationSettingsFeature.TimePickerState
    typealias Action = PushNotificationSettingsFeature.Action.TimePicker

    var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

extension DependencyValues {
    var fetchPushSettingsUseCase: FetchPushSettingsUseCase {
        get { self[FetchPushSettingsUseCaseKey.self] }
        set { self[FetchPushSettingsUseCaseKey.self] = newValue }
    }

    var updatePushSettingsUseCase: UpdatePushSettingsUseCase {
        get { self[UpdatePushSettingsUseCaseKey.self] }
        set { self[UpdatePushSettingsUseCaseKey.self] = newValue }
    }
}

private enum FetchPushSettingsUseCaseKey: DependencyKey {
    static var liveValue: FetchPushSettingsUseCase {
        preconditionFailure("FetchPushSettingsUseCase must be provided.")
    }

    static var testValue: FetchPushSettingsUseCase {
        liveValue
    }
}

private enum UpdatePushSettingsUseCaseKey: DependencyKey {
    static var liveValue: UpdatePushSettingsUseCase {
        preconditionFailure("UpdatePushSettingsUseCase must be provided.")
    }

    static var testValue: UpdatePushSettingsUseCase {
        liveValue
    }
}

extension PushNotificationSettingsFeature {
    static func activeLoadingRow(for date: Date) -> ActiveLoadingRow? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
              let minute = components.minute else { return nil }
        return .presetTime(hour: hour, minute: minute)
    }
}

private extension PushNotificationSettingsFeature {
    func fetchPushNotificationSettingsEffect() -> Effect<Action> {
        .run { [fetchPushSettingsUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                let settings = try await fetchPushSettingsUseCase.execute()
                await send(.applyFetchedSettings(settings))
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.clearActiveLoadingRow)
            } catch {
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.clearActiveLoadingRow)
                await send(.setAlert)
            }
        }
    }

    func updatePushNotificationSettingsEffect(
        settings: PushNotificationSettings,
        dismissesTimePickerOnSuccess: Bool = false
    ) -> Effect<Action> {
        .run { [updatePushSettingsUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                try await updatePushSettingsUseCase.execute(settings)
                await send(.loading(.end(target: .default, mode: .delayed)))
                if dismissesTimePickerOnSuccess {
                    await send(.timePicker(.dismiss))
                }
                await send(.clearActiveLoadingRow)
            } catch {
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.clearActiveLoadingRow)
                await send(.setAlert)
                await send(.fetchSettings)
            }
        }
    }

    static func settings(from state: State) -> PushNotificationSettings {
        let date = state.timePicker?.time ?? state.viewPushNotificationTime
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        return PushNotificationSettings(
            isEnabled: state.pushNotificationEnable,
            scheduledTime: dateComponents
        )
    }

    static func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: "common_error_message", bundle: PresentationResources.bundle))
        }
    }
}
