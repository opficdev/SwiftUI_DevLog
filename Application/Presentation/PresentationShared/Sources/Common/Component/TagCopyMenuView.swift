//
//  TagCopyMenuView.swift
//  PresentationShared
//
//  Created by opfic on 8/9/26.
//

import SwiftUI
import UIKit

struct TagCopyMenuView: UIViewRepresentable {
    let tagText: String

    func makeCoordinator() -> TagCopyMenuCoordinator {
        TagCopyMenuCoordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        context.coordinator.install(on: view)
        context.coordinator.tagText = tagText
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.tagText = tagText
    }
}

final class TagCopyMenuCoordinator: NSObject {
    var tagText = ""
    private weak var view: UIView?
    private var editMenuInteraction: UIEditMenuInteraction?

    func install(on view: UIView) {
        self.view = view

        let editMenuInteraction = UIEditMenuInteraction(delegate: self)
        view.addInteraction(editMenuInteraction)
        self.editMenuInteraction = editMenuInteraction

        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPressGesture(_:))
        )
        longPressGesture.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.direct.rawValue),
            NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)
        ]
        longPressGesture.cancelsTouchesInView = false
        longPressGesture.delegate = self
        view.addGestureRecognizer(longPressGesture)

        let secondaryClickGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleSecondaryClickGesture(_:))
        )
        secondaryClickGesture.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)
        ]
        secondaryClickGesture.buttonMaskRequired = .secondary
        secondaryClickGesture.cancelsTouchesInView = false
        secondaryClickGesture.delegate = self
        view.addGestureRecognizer(secondaryClickGesture)
    }

    @objc
    private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let view else { return }

        presentEditMenu(at: gesture.location(in: view))
    }

    @objc
    private func handleSecondaryClickGesture(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let view else { return }

        presentEditMenu(at: gesture.location(in: view))
    }

    private func presentEditMenu(at sourcePoint: CGPoint) {
        let configuration = UIEditMenuConfiguration(
            identifier: nil,
            sourcePoint: sourcePoint
        )
        editMenuInteraction?.presentEditMenu(with: configuration)
    }
}

extension TagCopyMenuCoordinator: UIEditMenuInteractionDelegate {
    func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        menuFor configuration: UIEditMenuConfiguration,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        let tagText = tagText
        let copyAction = UIAction(title: String(localized: "common_copy", bundle: PresentationResources.bundle)) { _ in
            UIPasteboard.general.string = tagText
        }
        return UIMenu(children: [copyAction])
    }

    func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        targetRectFor configuration: UIEditMenuConfiguration
    ) -> CGRect {
        view?.bounds ?? .zero
    }
}

extension TagCopyMenuCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
