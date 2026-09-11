//
//  SettingsFeatureTests.swift
//  ProfileTabTests
//
//  Created by opfic on 6/12/26.
//

import Core
import Domain
import Foundation
import PresentationShared
import Testing
@testable import ProfileTab

@MainActor
struct SettingsFeatureTests {
    @Test("prod 환경이면 베타 테스트 URL을 제공한다")
    func prod_환경이면_베타_테스트_URL을_제공한다() {
        let url = SettingsFeature.State.betaTestURL(
            appEnvironment: "prod",
            testFlightURL: "https://testflight.apple.com/join/b8mpr4UN"
        )

        #expect(url == URL(string: "https://testflight.apple.com/join/b8mpr4UN"))
    }

    @Test("staging 환경이면 베타 테스트 URL을 제공하지 않는다")
    func staging_환경이면_베타_테스트_URL을_제공하지_않는다() {
        let url = SettingsFeature.State.betaTestURL(
            appEnvironment: "staging",
            testFlightURL: "https://testflight.apple.com/join/b8mpr4UN"
        )

        #expect(url == nil)
    }

    @Test("미치환 환경값이면 베타 테스트 URL을 제공하지 않는다")
    func 미치환_환경값이면_베타_테스트_URL을_제공하지_않는다() {
        let url = SettingsFeature.State.betaTestURL(
            appEnvironment: "$(APP_ENVIRONMENT)",
            testFlightURL: "https://testflight.apple.com/join/b8mpr4UN"
        )

        #expect(url == nil)
    }

    @Test("네트워크 상태 관찰 결과를 상태에 반영한다")
    func 네트워크_상태_관찰_결과를_상태에_반영한다() async {
        let networkSpy = ObserveNetworkConnectivityUseCaseSpy()
        let adapter = SettingsStoreTestAdapter(networkUseCase: networkSpy)

        await adapter.startObserving()
        networkSpy.currentValueSubject.send(false)
        await adapter.drainReceivedActions()

        #expect(!adapter.isNetworkConnected)
    }

    @Test("테마를 변경하면 상태를 갱신하고 설정 저장을 요청한다")
    func 테마를_변경하면_상태를_갱신하고_설정_저장을_요청한다() async {
        let updateSpy = UpdateSystemThemeUseCaseSpy()
        let adapter = SettingsStoreTestAdapter(updateThemeUseCase: updateSpy)

        await adapter.setTheme(.dark)

        #expect(adapter.theme == .dark)
        #expect(updateSpy.themes == [.dark])
    }

    @Test("테마 관찰 결과를 상태에 반영한다")
    func 테마_관찰_결과를_상태에_반영한다() async {
        let themeSpy = ObserveSystemThemeUseCaseSpy()
        let updateSpy = UpdateSystemThemeUseCaseSpy()
        let adapter = SettingsStoreTestAdapter(
            themeUseCase: themeSpy,
            updateThemeUseCase: updateSpy
        )

        await adapter.startObserving()
        themeSpy.subject.send(.light)
        await adapter.drainReceivedActions()

        #expect(adapter.theme == .light)
        #expect(updateSpy.themes == [.light])
    }

    @Test("로그아웃 성공 후에도 LoginView 전환 전까지 로딩 상태를 유지한다")
    func 로그아웃_성공_후에도_LoginView_전환_전까지_로딩_상태를_유지한다() async {
        let signOutSpy = SignOutUseCaseSpy()
        signOutSpy.shouldSuspend = true
        let adapter = SettingsStoreTestAdapter(signOutUseCase: signOutSpy)

        await adapter.tapSignOutButton()

        #expect(!adapter.isLoading)

        await adapter.advanceDelayedLoading()

        #expect(adapter.isLoading)
        #expect(adapter.activeLoadingRow == .signOut)

        signOutSpy.resume()
        await adapter.drainReceivedActions()

        #expect(adapter.isLoading)
        #expect(adapter.activeLoadingRow == .signOut)
    }

    @Test("로그아웃 실패 시 로딩 row 상태를 해제한다")
    func 로그아웃_실패_시_로딩_row_상태를_해제한다() async {
        let signOutSpy = SignOutUseCaseSpy()
        signOutSpy.error = SettingsTestError.failure
        let adapter = SettingsStoreTestAdapter(signOutUseCase: signOutSpy)

        await adapter.tapSignOutButton()

        #expect(adapter.showAlert)
        #expect(adapter.activeLoadingRow == nil)
    }

    @Test("회원 탈퇴 실패 시 공통 에러 알림을 표시한다")
    func 회원_탈퇴_실패_시_공통_에러_알림을_표시한다() async {
        let deleteSpy = DeleteAuthUseCaseSpy()
        deleteSpy.error = SettingsTestError.failure
        let adapter = SettingsStoreTestAdapter(deleteAuthUseCase: deleteSpy)

        await adapter.tapDeleteAuthButton()

        #expect(deleteSpy.executeCallCount == 1)
        #expect(adapter.showAlert)
        #expect(adapter.alertTitle == String(localized: "common_error_title", bundle: PresentationResources.bundle))
        #expect(adapter.activeLoadingRow == nil)
    }
}

private enum SettingsAlertType {
    case signOut
    case deleteAuth
    case error
}

@MainActor
private struct SettingsStoreTestAdapter {
    private let store: TestStoreOf<SettingsFeature>
    private let clock: TestClock<Duration>

    var theme: SystemTheme { store.state.theme }
    var isNetworkConnected: Bool { store.state.isNetworkConnected }
    var isLoading: Bool { store.state.isLoading }
    var activeLoadingRow: SettingsFeature.ActiveLoadingRow? { store.state.activeLoadingRow }
    var showAlert: Bool { store.state.alert != nil }
    var alertTitle: String {
        guard let alert = store.state.alert else { return "" }
        return String(state: alert.title)
    }
    var alertMessage: String {
        store.state.alert?.message.map { String(state: $0) } ?? ""
    }
    var alertType: SettingsAlertType? {
        guard let type = store.state.alertType else { return nil }
        return SettingsAlertType(type)
    }

    init(
        deleteAuthUseCase: DeleteAuthUseCase = DeleteAuthUseCaseSpy(),
        signOutUseCase: SignOutUseCase = SignOutUseCaseSpy(),
        networkUseCase: ObserveNetworkConnectivityUseCase = ObserveNetworkConnectivityUseCaseSpy(),
        themeUseCase: ObserveSystemThemeUseCase = ObserveSystemThemeUseCaseSpy(),
        updateThemeUseCase: UpdateSystemThemeUseCase = UpdateSystemThemeUseCaseSpy()
    ) {
        let clock = TestClock()
        self.clock = clock
        store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.deleteAuthUseCase = deleteAuthUseCase
            $0.signOutUseCase = signOutUseCase
            $0.profileNetworkConnectivityUseCase = networkUseCase
            $0.profileSystemThemeUseCase = themeUseCase
            $0.updateSystemThemeUseCase = updateThemeUseCase
            $0.continuousClock = clock
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func startObserving() async {
        await store.send(.startObserving)
    }

    func setTheme(_ theme: SystemTheme) async {
        await store.send(.binding(.set(\.theme, theme))) {
            $0.theme = theme
        }
    }

    func tapSignOutButton() async {
        await store.send(.setAlert(.signOut)) {
            $0.alert = expectedSettingsAlert(for: .signOut)
            $0.alertType = .signOut
        }
        await store.send(.alert(.presented(.tapSignOutButton))) {
            $0.alert = nil
            $0.alertType = nil
            $0.activeLoadingRow = .signOut
        }
        await drainReceivedActions()
    }

    func tapDeleteAuthButton() async {
        await store.send(.setAlert(.deleteAuth)) {
            $0.alert = expectedSettingsAlert(for: .deleteAuth)
            $0.alertType = .deleteAuth
        }
        await store.send(.alert(.presented(.tapDeleteAuthButton))) {
            $0.alert = nil
            $0.alertType = nil
            $0.activeLoadingRow = .deleteAuth
        }
        await drainReceivedActions()
    }

    func advanceDelayedLoading() async {
        let target = LoadingFeature.Target.default
        await clock.advance(by: .milliseconds(300))
        await store.receive(\.loading.delayedLoadingDidBecomeVisible, target) {
            $0.loading.scheduledDelayedTargets = []
            $0.loading.visibleDelayedTargets = [target]
            $0.loading.visibleTargets = [target]
            $0.loading.isLoading = true
        }
    }

    func drainReceivedActions() async {
        await store.skipReceivedActions(strict: false)
        await store.skipReceivedActions(strict: false)
        await store.skipReceivedActions(strict: false)
        await store.skipReceivedActions(strict: false)
    }
}

private extension SettingsAlertType {
    init(_ type: SettingsFeature.Action.AlertType) {
        switch type {
        case .signOut:
            self = .signOut
        case .deleteAuth:
            self = .deleteAuth
        case .error:
            self = .error
        }
    }
}

private func expectedSettingsAlert(
    for type: SettingsFeature.Action.AlertType
) -> AlertState<SettingsFeature.Action.Alert> {
    switch type {
    case .signOut:
        return AlertState {
            TextState(String(localized: "settings_alert_sign_out_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_cancel", bundle: PresentationResources.bundle))
            }
            ButtonState(role: .destructive, action: .tapSignOutButton) {
                TextState(String(localized: "common_confirm", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: "settings_alert_sign_out_message", bundle: PresentationResources.bundle))
        }
    case .deleteAuth:
        return AlertState {
            TextState(String(localized: "settings_alert_delete_account_title", bundle: PresentationResources.bundle))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_cancel", bundle: PresentationResources.bundle))
            }
            ButtonState(role: .destructive, action: .tapDeleteAuthButton) {
                TextState(String(localized: "settings_delete_account_action", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(String(localized: "settings_alert_delete_account_message", bundle: PresentationResources.bundle))
        }
    case .error:
        return AlertState {
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
