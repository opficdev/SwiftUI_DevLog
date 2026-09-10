//
//  RootFeatureTests.swift
//  EntryTests
//
//  Created by opfic on 6/17/26.
//

import Core
import Foundation
import PresentationShared
import Testing

@MainActor
struct RootFeatureTests {
    @Test("RootFeature networkStatusChanged는 기존 Root 상태관리처럼 alert 문구와 표시 상태를 갱신한다")
    func RootFeature_networkStatusChanged는_기존_Root_상태관리처럼_alert_문구와_표시_상태를_갱신한다() async {
        let adapter = RootStoreTestAdapter()

        await verifyNetworkDisconnectedAlert(adapter: adapter)
    }

    @Test("RootFeature setAlert(false)는 기존 Root 상태관리처럼 alert 문구를 유지한 채 표시 상태를 해제한다")
    func RootFeature_setAlert_false는_기존_Root_상태관리처럼_alert_문구를_유지한_채_표시_상태를_해제한다() async {
        let adapter = RootStoreTestAdapter()

        await verifySetAlert(adapter: adapter)
    }

    @Test("RootFeature setTheme은 기존 Root 상태관리처럼 테마 상태를 갱신한다")
    func RootFeature_setTheme은_기존_Root_상태관리처럼_테마_상태를_갱신한다() async {
        let adapter = RootStoreTestAdapter()

        await verifyThemeUpdate(adapter: adapter)
    }

    @Test("RootFeature didLogined(false)는 기존 Root 상태관리처럼 signIn 상태를 갱신하고 login 화면 추적을 요청한다")
    func RootFeature_didLogined_false는_기존_Root_상태관리처럼_signIn_상태를_갱신하고_login_화면_추적을_요청한다() async {
        let trackSpy = RootTrackAnalyticsEventUseCaseSpy()
        let adapter = RootStoreTestAdapter(trackAnalyticsEventUseCase: trackSpy)

        await verifyDidLoginedFalse(adapter: adapter, trackAnalyticsEventUseCaseSpy: trackSpy)
    }

    @Test("RootFeature didLogined(false)는 앱 badge 초기화를 요청한다")
    func RootFeature_didLogined_false는_앱_badge_초기화를_요청한다() async {
        let badgeSpy = RootApplicationBadgeCountSpy()
        let adapter = RootStoreTestAdapter(badgeCountSpy: badgeSpy)

        await adapter.didLogined(false)
        await waitUntil {
            badgeSpy.counts == [0]
        }

        #expect(badgeSpy.counts == [0])
    }

    @Test("RootFeature didLogined(true)는 기존 Root 상태관리처럼 signIn 상태를 true로 갱신하고 selectedMainTab을 home으로 되돌린다")
    func RootFeature_didLogined_true는_기존_Root_상태관리처럼_signIn_상태를_true로_갱신하고_selectedMainTab을_home으로_되돌린다() async {
        let trackSpy = RootTrackAnalyticsEventUseCaseSpy()
        let adapter = RootStoreTestAdapter(trackAnalyticsEventUseCase: trackSpy)

        await verifyDidLoginedTrue(adapter: adapter, trackAnalyticsEventUseCaseSpy: trackSpy)
    }

    @Test("RootFeature onAppear는 기존 Root 상태관리처럼 session, network, theme 관찰을 한 번만 시작한다")
    func RootFeature_onAppear는_기존_Root_상태관리처럼_session_network_theme_관찰을_한_번만_시작한다() async {
        let sessionSpy = ObserveAuthSessionUseCaseSpy(currentValue: true)
        let networkSpy = RootObserveNetworkConnectivityUseCaseSpy(currentValue: true)
        let themeSpy = RootObserveSystemThemeUseCaseSpy(currentValue: .automatic)
        let adapter = RootStoreTestAdapter(
            sessionUseCase: sessionSpy,
            networkConnectivityUseCase: networkSpy,
            systemThemeUseCase: themeSpy
        )

        await adapter.onAppear()
        await adapter.onAppear()

        #expect(sessionSpy.observeCallCount == 1)
        #expect(networkSpy.observeCallCount == 1)
        #expect(themeSpy.observeCallCount == 1)
    }

    @Test("RootFeature onAppear는 기존 Root 상태관리처럼 초기 publisher 값으로 signIn, network, theme 상태를 반영한다")
    func RootFeature_onAppear는_기존_Root_상태관리처럼_초기_publisher_값으로_signIn_network_theme_상태를_반영한다() async {
        let adapter = RootStoreTestAdapter(
            sessionUseCase: ObserveAuthSessionUseCaseSpy(currentValue: false),
            networkConnectivityUseCase: RootObserveNetworkConnectivityUseCaseSpy(currentValue: false),
            systemThemeUseCase: RootObserveSystemThemeUseCaseSpy(currentValue: .dark)
        )

        await verifyObservedInitialValues(adapter: adapter)
    }

    @Test("RootFeature onAppear는 앱 badge 초기화를 요청한다")
    func RootFeature_onAppear는_앱_badge_초기화를_요청한다() async {
        let badgeSpy = RootApplicationBadgeCountSpy()
        let adapter = RootStoreTestAdapter(badgeCountSpy: badgeSpy)

        await adapter.onAppear()
        await adapter.onAppear()
        await waitUntil {
            badgeSpy.counts == [0, 0]
        }

        #expect(badgeSpy.counts == [0, 0])
    }

    @Test("RootFeature onAppear는 로그인 상태와 무관하게 업데이트를 한 번만 확인한다")
    func RootFeature_onAppear는_로그인_상태와_무관하게_업데이트를_한_번만_확인한다() async {
        let checkSpy = RootCheckAppUpdateUseCaseSpy()
        let adapter = RootStoreTestAdapter(
            sessionUseCase: ObserveAuthSessionUseCaseSpy(currentValue: false),
            checkAppUpdateUseCase: checkSpy
        )

        await adapter.onAppear()
        await adapter.onAppear()

        #expect(await checkSpy.executeCallCount() == 1)
    }

    @Test("업데이트 확인에 실패하면 업데이트 알림을 표시하지 않는다")
    func 업데이트_확인에_실패하면_업데이트_알림을_표시하지_않는다() async {
        let checkSpy = RootCheckAppUpdateUseCaseSpy(
            result: .failure(RootCheckAppUpdateUseCaseTestError.fetchFailed)
        )
        let adapter = RootStoreTestAdapter(checkAppUpdateUseCase: checkSpy)

        await adapter.onAppear()

        #expect(await checkSpy.executeCallCount() == 1)
        #expect(adapter.snapshot.alertTitle == nil)
        #expect(adapter.snapshot.alertMessage == nil)
    }

    @Test("필수 업데이트 알림은 네트워크 연결 알림보다 우선한다")
    func 필수_업데이트_알림은_네트워크_연결_알림보다_우선한다() async {
        let adapter = RootStoreTestAdapter(
            networkConnectivityUseCase: RootObserveNetworkConnectivityUseCaseSpy(currentValue: false),
            checkAppUpdateUseCase: RootCheckAppUpdateUseCaseSpy(result: .success(true))
        )

        await adapter.onAppear()

        #expect(
            adapter.snapshot.alertTitle
                == String(localized: "root_app_update_title", bundle: PresentationResources.bundle)
        )
        #expect(
            adapter.snapshot.alertMessage
                == String(localized: "root_app_update_message", bundle: PresentationResources.bundle)
        )
    }

    @Test("업데이트 버튼은 App Store 열기를 요청한다")
    func 업데이트_버튼은_App_Store_열기를_요청한다() async throws {
        let appStoreURL = try #require(URL(string: "https://apps.apple.com/us/app/devlog/id6760288611"))
        let openSpy = RootOpenURLSpy()
        let adapter = RootStoreTestAdapter(
            checkAppUpdateUseCase: RootCheckAppUpdateUseCaseSpy(result: .success(true)),
            appStoreURL: appStoreURL,
            openURLSpy: openSpy
        )

        await adapter.onAppear()
        await adapter.tapUpdateButton()
        await waitUntil {
            await openSpy.openCallCount() == 1
        }

        #expect(await openSpy.openCallCount() == 1)
        #expect(await openSpy.openedURLs() == [appStoreURL])
    }

    @Test("RootFeature는 TodoDetail sheet 표시와 해제를 store state로 관리한다")
    func RootFeature는_TodoDetail_sheet_표시와_해제를_store_state로_관리한다() async {
        let adapter = RootStoreTestAdapter()

        await verifyTodoDetailSheetPresentation(adapter: adapter)
    }

    @Test("RootFeature는 로그인된 경우에만 widget route로 selectedMainTab을 변경한다")
    func RootFeature는_로그인된_경우에만_widget_route로_selectedMainTab을_변경한다() async {
        let adapter = RootStoreTestAdapter()

        await verifyWidgetRouteOpensWhenSignedIn(adapter: adapter)
    }
}

private enum RootCheckAppUpdateUseCaseTestError: Error {
    case fetchFailed
}
