//
//  TodoInspectorInteractionView.swift
//  TodayTab
//
//  Created by opfic on 9/13/26.
//

import SwiftUI

struct TodoInspectorInteractionView: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> TodoInspectorInteractionCoordinator {
        TodoInspectorInteractionCoordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        context.coordinator.update(action: action)
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.update(action: action)
    }
}

final class TodoInspectorInteractionCoordinator: NSObject {
    private weak var view: UIView?
    private var contextMenuInteraction: UIContextMenuInteraction?
    private var action: (() -> Void)?

    func update(action: @escaping () -> Void) {
        self.action = action
    }

    func install(on view: UIView) {
        guard self.view !== view else { return }

        if let contextMenuInteraction {
            self.view?.removeInteraction(contextMenuInteraction)
        }

        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        view.addInteraction(contextMenuInteraction)
        self.view = view
        self.contextMenuInteraction = contextMenuInteraction
    }
}

extension TodoInspectorInteractionCoordinator: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        action?()
        return nil
    }
}
