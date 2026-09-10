//
//  LoginFeatureTests.swift
//  EntryTests
//
//  Created by opfic on 6/5/26.
//

import Testing
import Core
import PresentationShared
import Foundation
import Domain
@testable import Entry

@MainActor
struct LoginFeatureTests {
    @Test("로그인 버튼을 누르면 선택한 인증 제공자로 로그인 유스케이스가 호출된다")
    func 로그인_버튼을_누르면_선택한_인증_제공자로_로그인_유스케이스가_호출된다() async {
        let spy = SignInUseCaseSpy()
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.github)

        await waitUntil {
            spy.calledProviders == [.github]
        }

        #expect(spy.calledProviders == [.github])
        #expect(spy.calledPresentationContextIdentifiers == ["scene-id"])
    }

    @Test("로그인 성공 후에도 메인 화면 전환 전까지 로딩 상태를 유지한다")
    func 로그인_성공_후에도_메인_화면_전환_전까지_로딩_상태를_유지한다() async {
        let spy = SignInUseCaseSpy()
        spy.shouldSuspend = true
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            driver.isLoading
        }

        #expect(driver.isLoading)
        #expect(driver.activeSignInProvider == .google)

        spy.resume()

        await waitUntil {
            spy.successfulProviders == [.google]
        }

        #expect(driver.isLoading)
        #expect(driver.activeSignInProvider == .google)
    }

    @Test("로그인 실패 후에도 로딩 상태가 꺼진다")
    func 로그인_실패_후에도_로딩_상태가_꺼진다() async {
        let spy = SignInUseCaseSpy()
        spy.shouldSuspend = true
        spy.error = AuthError.unsupportedProvider
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.apple)

        await waitUntil {
            driver.isLoading
        }

        #expect(driver.isLoading)

        spy.resume()

        await waitUntil {
            !driver.isLoading && driver.hasAlert
        }

        #expect(!driver.isLoading)
        #expect(driver.activeSignInProvider == nil)
    }

    @Test("이메일을 가져오지 못하면 이메일 없음 알림을 표시한다")
    func 이메일을_가져오지_못하면_이메일_없음_알림을_표시한다() async {
        let spy = SignInUseCaseSpy()
        spy.error = AuthError.emailNotFound
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            driver.hasAlert
        }

        #expect(driver.alert == expectedAlert(
            title: String(localized: "login_alert_email_unavailable_title", bundle: PresentationResources.bundle),
            message: String(localized: "login_alert_email_unavailable_message", bundle: PresentationResources.bundle)
        ))
    }

    @Test("일반 로그인 에러가 발생하면 공통 에러 알림을 표시한다")
    func 일반_로그인_에러가_발생하면_공통_에러_알림을_표시한다() async {
        let spy = SignInUseCaseSpy()
        spy.error = AuthError.unsupportedProvider
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.apple)

        await waitUntil {
            driver.hasAlert
        }

        #expect(driver.alert == expectedAlert(
            title: String(localized: "common_error_title", bundle: PresentationResources.bundle),
            message: String(localized: "common_error_message", bundle: PresentationResources.bundle)
        ))
    }

    @Test("소셜 로그인이 취소되어도 알림을 표시하지 않는다")
    func 소셜_로그인이_취소되어도_알림을_표시하지_않는다() async {
        let spy = SignInUseCaseSpy()
        spy.signedIn = false
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            spy.calledProviders == [.google] && !driver.isLoading
        }

        #expect(!driver.showAlert)
        #expect(driver.alert == nil)
    }

    @Test("알림을 닫으면 알림 상태와 문구가 초기화된다")
    func 알림을_닫으면_알림_상태와_문구가_초기화된다() async {
        let spy = SignInUseCaseSpy()
        spy.error = AuthError.emailNotFound
        let driver = LoginTestDriver(useCase: spy)

        driver.tapSignInButton(.google)

        await waitUntil {
            driver.hasAlert
        }

        driver.dismissAlert()

        #expect(!driver.showAlert)
        #expect(driver.alert == nil)
    }
}

@MainActor
private struct LoginTestDriver {
    private let feature: StoreOf<LoginFeature>

    var isLoading: Bool {
        feature.state.isLoading
    }

    var activeSignInProvider: AuthProvider? {
        feature.state.activeSignInProvider
    }

    var showAlert: Bool {
        hasAlert
    }

    var hasAlert: Bool {
        alert != nil
    }

    var alert: AlertState<Never>? {
        feature.state.alert
    }

    init(useCase: SignInUseCase) {
        var state = LoginFeature.State()
        state.presentationContext = AuthPresentationContext(identifier: "scene-id")
        feature = ComposableArchitecture.Store(
            initialState: state
        ) {
            LoginFeature()
        } withDependencies: {
            $0.signInUseCase = useCase
        }
    }

    func tapSignInButton(_ provider: AuthProvider) {
        feature.send(.tapSignInButton(provider))
    }

    func dismissAlert() {
        feature.send(.alert(.dismiss))
    }
}

private func expectedAlert(
    title: String,
    message: String
) -> AlertState<Never> {
    AlertState {
        TextState(title)
    } actions: {
        ButtonState(role: .cancel) {
            TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
        }
    } message: {
        TextState(message)
    }
}
