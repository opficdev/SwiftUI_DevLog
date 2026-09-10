//
//  LoginFeature.swift
//  Entry
//
//  Created by opfic on 6/5/26.
//

import Foundation
import Core
import Domain
import PresentationShared

@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        var activeSignInProvider: AuthProvider?
        var loading = LoadingFeature.State()
        var presentationContext: AuthPresentationContext?

        var isLoading: Bool {
            loading.isLoading
        }
    }

    enum Action {
        case alert(PresentationAction<Never>)
        case tapSignInButton(AuthProvider)
        case setPresentationContext(AuthPresentationContext?)
        case signInFailed(AlertType)
        case loading(LoadingFeature.Action)
    }

    enum AlertType: Equatable {
        case emailUnavailable
        case error
    }

    @Dependency(\.signInUseCase) var signInUseCase

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .tapSignInButton(let provider):
                guard !state.isLoading,
                      let context = state.presentationContext
                else {
                    return .none
                }
                state.activeSignInProvider = provider
                return signInEffect(
                    provider,
                    context: context
                )
            case .setPresentationContext(let context):
                state.presentationContext = context
            case .signInFailed(let alertType):
                state.alert = Self.alertState(for: alertType)
            case .loading:
                if !state.isLoading {
                    state.activeSignInProvider = nil
                }
            }
            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension DependencyValues {
    var signInUseCase: SignInUseCase {
        get { self[SignInUseCaseKey.self] }
        set { self[SignInUseCaseKey.self] = newValue }
    }
}

private enum SignInUseCaseKey: DependencyKey {
    static var liveValue: SignInUseCase {
        preconditionFailure("SignInUseCase must be provided.")
    }

    static var testValue: SignInUseCase {
        liveValue
    }
}

private extension LoginFeature {
    func signInEffect(
        _ provider: AuthProvider,
        context: AuthPresentationContext
    ) -> Effect<Action> {
        .run { [signInUseCase] send in
            await send(.loading(.begin(target: .default, mode: .immediate)))
            do {
                let signedIn = try await AuthPresentationContext
                    .$current
                    .withValue(context) {
                        try await signInUseCase.execute(provider)
                    }
                // 유스케이스 완료가 화면 전환 완료를 의미하지 않으므로 LoginView가 교체될 때까지 로딩을 유지한다.
                guard !signedIn else { return }
                await send(.loading(.end(target: .default, mode: .immediate)))
            } catch {
                await send(.loading(.end(target: .default, mode: .immediate)))
                await send(.signInFailed(Self.alertType(for: error)))
            }
        }
    }

    static func alertState(for alertType: AlertType) -> AlertState<Never> {
        let title: String
        let message: String

        switch alertType {
        case .emailUnavailable:
            title = String(localized: "login_alert_email_unavailable_title", bundle: PresentationResources.bundle)
            message = String(localized: "login_alert_email_unavailable_message", bundle: PresentationResources.bundle)
        case .error:
            title = String(localized: "common_error_title", bundle: PresentationResources.bundle)
            message = String(localized: "common_error_message", bundle: PresentationResources.bundle)
        }

        return AlertState {
            TextState(title)
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close", bundle: PresentationResources.bundle))
            }
        } message: {
            TextState(message)
        }
    }

    static func alertType(for error: Error) -> AlertType {
        if case AuthError.emailNotFound = error {
            return .emailUnavailable
        }

        return .error
    }
}
