//
//  TodoMarkdownContentView.swift
//  PresentationShared
//
//  Created by opfic on 3/25/26.
//

import SwiftUI
import Domain
import MarkdownRenderer

struct TodoMarkdownContentView: View {
    let content: String
    let referenceItems: [Int: TodoReferenceItem]
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        MarkdownRendererView(
            markdown: content,
            references: rendererReferences,
            onOpenReferenceID: onOpenTodoID
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var rendererReferences: [Int: MarkdownRendererReference] {
        referenceItems.mapValues { item in
            MarkdownRendererReference(
                referenceID: item.id,
                title: item.title,
                colorHex: item.category.color.hexValue ?? "#808080",
                iconDataURL: iconDataURL(for: item.category.symbolName)
            )
        }
    }

    private func iconDataURL(for symbolName: String) -> String? {
        let configuration = UIImage.SymbolConfiguration(
            pointSize: 11,
            weight: .bold
        )

        guard
            let image = UIImage(
                systemName: symbolName,
                withConfiguration: configuration
            )?.withTintColor(.white, renderingMode: .alwaysOriginal),
            let data = image.pngData()
        else {
            return nil
        }

        return "data:image/png;base64,\(data.base64EncodedString())"
    }
}
