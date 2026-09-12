//
//  Toast.swift
//  PresentationShared
//
//  Created by 최윤진 on 2/10/26.
//

import SwiftUI

@MainActor
@Observable
public final class ToastPresenter {
    fileprivate static let presenter = ToastPresenter()

    public private(set) var item: ToastItem?

    private init() { }

    public static var item: ToastItem? {
        presenter.item
    }

    public static func present(
        message: String,
        systemImage: String? = nil,
        duration: TimeInterval = 2,
        font: Font? = nil,
        multilineTextAlignment: TextAlignment = .leading,
        lineLimit: Int? = nil,
        action: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        presenter.present(
            ToastItem(
                message: message,
                systemImage: systemImage,
                duration: duration,
                font: font,
                multilineTextAlignment: multilineTextAlignment,
                lineLimit: lineLimit,
                action: action,
                onDismiss: onDismiss
            )
        )
    }

    public static func reset() {
        presenter.item = nil
    }

    private func present(_ item: ToastItem) {
        dismissImmediately()
        self.item = item
    }

    fileprivate func dismiss(itemId: UUID) {
        guard let item,
              item.id == itemId else { return }
        self.item = nil
    }

    private func dismissImmediately() {
        guard let item else { return }
        self.item = nil
        item.onDismiss?()
    }
}

public struct ToastItem: Identifiable {
    public let id = UUID()
    public let message: String
    public let systemImage: String?
    public let duration: TimeInterval
    public let font: Font?
    public let multilineTextAlignment: TextAlignment
    public let lineLimit: Int?
    public let action: (() -> Void)?
    public let onDismiss: (() -> Void)?
}

public extension View {
    func toastHost() -> some View {
        modifier(ToastHostModifier())
    }
}

private struct ToastHostModifier: ViewModifier {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @State private var tabBarHeight = CGFloat.zero
    private let toastPresenter = ToastPresenter.presenter
    private let placement = ToastPresentationPlacement.current

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                updateTabBarHeight()
            }
            .onChange(of: toastPresenter.item?.id) { _, _ in
                updateTabBarHeight()
            }
            .overlay(alignment: placement.alignment) {
                if let item = toastPresenter.item {
                    ToastOverlayView(
                        isPresented: Binding(
                            get: { toastPresenter.item?.id == item.id },
                            set: { isPresented in
                                if !isPresented {
                                    toastPresenter.dismiss(itemId: item.id)
                                }
                            }
                        ),
                        duration: item.duration,
                        presentedOffset: placement.presentedOffset,
                        action: item.action,
                        onDismiss: item.onDismiss
                    ) {
                        ToastItemLabel(item: item)
                    }
                    .id(item.id)
                    .padding(.horizontal, 12)
                    .padding(.bottom, placement.bottomPadding(toastBottomInset))
                }
            }
    }

    private var toastBottomInset: CGFloat {
        max(0, tabBarHeight - safeAreaInsets.bottom)
    }

    @MainActor
    private func updateTabBarHeight() {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        guard let window else {
            tabBarHeight = .zero
            return
        }
        tabBarHeight = window.rootViewController?.visibleTabBarHeight ?? .zero
    }
}

private enum ToastPresentationPlacement {
    case top
    case bottom

    static var current: ToastPresentationPlacement {
        ProcessInfo.processInfo.isiOSAppOnMac ? .top : .bottom
    }

    var alignment: Alignment {
        switch self {
        case .top:
            return .top
        case .bottom:
            return .bottom
        }
    }

    var presentedOffset: CGFloat {
        switch self {
        case .top:
            return 50
        case .bottom:
            return -50
        }
    }

    func bottomPadding(_ inset: CGFloat) -> CGFloat {
        switch self {
        case .top:
            return 0
        case .bottom:
            return inset
        }
    }
}

private struct ToastItemLabel: View {
    let item: ToastItem

    var body: some View {
        Group {
            if let systemImage = item.systemImage {
                Label(item.message, systemImage: systemImage)
            } else {
                Text(item.message)
            }
        }
        .font(item.font)
        .multilineTextAlignment(item.multilineTextAlignment)
        .lineLimit(item.lineLimit)
    }
}

private struct ToastOverlayView<Label: View>: View {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let presentedOffset: CGFloat
    let action: (() -> Void)?
    let onDismiss: (() -> Void)?
    @ViewBuilder let label: () -> Label

    @State private var yOffset: CGFloat = 0
    @State private var opacityValue: Double = 0
    @State private var dismissWorkItem: DispatchWorkItem?
    @State private var dismissCompletionWorkItem: DispatchWorkItem?
    @State private var isTapped: Bool = false
    @State private var isScheduled: Bool = false

    var body: some View {
        if isPresented {
            ToastCardView(
                label,
                color: action == nil ? .primary : .blue
            )
            .offset(y: yOffset)
            .opacity(opacityValue)
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    resetForNewPresentation()
                    presentAnimated()
                    scheduleDismissIfNeeded()
                } else {
                    cleanupPresentation()
                }
            }
            .onAppear {
                presentAnimated()
                scheduleDismissIfNeeded()
            }
            .onDisappear {
                cleanupPresentation()
            }
            .onTapGesture {
                isTapped = true
                dismissAnimated()
                action?()
            }
            .transition(.identity)
        }
    }

    private func presentAnimated() {
        guard opacityValue == 0 else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 0.0)) {
            yOffset = presentedOffset
            opacityValue = 1
        }
    }

    private func resetForNewPresentation() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        dismissCompletionWorkItem?.cancel()
        dismissCompletionWorkItem = nil
        isScheduled = false
        isTapped = false
        yOffset = 0
        opacityValue = 0
    }

    private func cleanupPresentation() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        dismissCompletionWorkItem?.cancel()
        dismissCompletionWorkItem = nil
        isScheduled = false
        isTapped = false
        yOffset = 0
        opacityValue = 0
    }

    private func scheduleDismissIfNeeded() {
        guard !isScheduled else { return }
        isScheduled = true

        let workItem = DispatchWorkItem {
            dismissAnimated()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func dismissAnimated() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        dismissCompletionWorkItem?.cancel()

        withAnimation(.easeInOut(duration: 0.2)) {
            yOffset = 0
            opacityValue = 0
        }

        let workItem = DispatchWorkItem {
            isPresented = false
            isScheduled = false

            if !isTapped {
                onDismiss?()
            }
            isTapped = false
        }
        dismissCompletionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

private struct ToastCardView<Label: View>: View {
    @ViewBuilder let label: Label
    let color: Color

    init(
        @ViewBuilder _ label: @escaping () -> Label,
        color: Color = .primary
    ) {
        self.label = label()
        self.color = color
    }

    var body: some View {
        self.label
            .foregroundStyle(color)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .glassEffect()
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
    }
}
