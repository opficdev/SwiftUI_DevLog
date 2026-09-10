//
//  ToolbarButtons.swift
//  PresentationShared
//
//  Created by 최윤진 on 3/1/26.
//

import SwiftUI
import Domain

public struct ToolbarLeadingButton: ToolbarContent {
    var action: (() -> Void)?

    public init(action: (() -> Void)? = nil) {
        self.action = action
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if #available(iOS 26.0, *) {
                Button(role: .cancel) {
                    action?()
                }
            } else {
                Button {
                    action?()
                } label: {
                    Text(String(localized: "common_cancel", bundle: PresentationResources.bundle))
                }
            }
        }
    }
}

public struct ToolbarTrailingButton: ToolbarContent {
    var action: (() -> Void)?
    private var isDisabled: Bool = false

    public init(action: (() -> Void)? = nil) {
        self.action = action
    }

    public func disabled(_ isDisabled: Bool) -> ToolbarTrailingButton {
        var copy = self
        copy.isDisabled = isDisabled
        return copy
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if #available(iOS 26.0, *) {
                Button(role: .confirm) {
                    action?()
                }
                .disabled(isDisabled)
            } else {
                Button {
                    action?()
                } label: {
                    Text(String(localized: "common_confirm", bundle: PresentationResources.bundle))
                        .bold()
                }
                .disabled(isDisabled)
            }
        }
    }
}
