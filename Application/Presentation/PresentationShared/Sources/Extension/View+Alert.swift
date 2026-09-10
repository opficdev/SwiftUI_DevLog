//
//  View+Alert.swift
//  PresentationShared
//
//  Created by opfic on 7/30/26.
//

import ComposableArchitecture
import SwiftUI

public extension View {
    @preconcurrency @MainActor
    @ViewBuilder
    func prominentAlert<State, Action, AlertAction>(
        _ store: Store<State, Action>,
        state: KeyPath<State, AlertState<AlertAction>?>,
        action: CaseKeyPath<Action, PresentationAction<AlertAction>>
    ) -> some View where State: ObservableState {
        modifier(
            ProminentAlertModifier(
                store: store,
                alertState: state,
                alertAction: action
            )
        )
    }
}

private struct ProminentAlertModifier<State, Action, AlertAction>: ViewModifier
where State: ObservableState {
    @Environment(\.isTabContentActive) private var isTabContentActive

    let store: Store<State, Action>
    let alertState: KeyPath<State, AlertState<AlertAction>?>
    let alertAction: CaseKeyPath<Action, PresentationAction<AlertAction>>

    @preconcurrency @MainActor
    func body(content: Content) -> some View {
        @Bindable var store = store
        let item = $store.scope(state: alertState, action: alertAction)
        let alertStore = item.wrappedValue
        let state = store.state[keyPath: alertState]

        content.alert(
            state.map(\.title).map(Text.init) ?? Text(verbatim: ""),
            isPresented: Binding(item).activePresentation(when: isTabContentActive),
            presenting: state,
            actions: { state in
                ForEach(state.buttons) { button in
                    let usesDefaultAction = state.usesDefaultAction(for: button)

                    Button(
                        role: state.buttonRole(for: button),
                        action: {
                            button.withAction { action in
                                if let action {
                                    alertStore?.send(action)
                                }
                            }
                        }
                    ) {
                        Text(button.label)
                    }
                    .keyboardShortcut(
                        usesDefaultAction ? .defaultAction : nil
                    )
                }
            },
            message: {
                $0.message.map(Text.init)
            }
        )
    }
}

extension AlertState {
    func buttonRole(for button: ButtonState<Action>) -> ButtonRole? {
        if #available(iOS 26, *), usesDefaultAction(for: button) { return .confirm }
        if buttons.count == 1 { return nil }
        return button.role.map(ButtonRole.init)
    }

    func usesDefaultAction(for button: ButtonState<Action>) -> Bool {
        guard 1 < buttons.count else { return true }
        return buttons.first { $0.role == .destructive }?.id == button.id
    }
}
