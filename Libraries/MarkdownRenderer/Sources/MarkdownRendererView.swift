//
//  MarkdownRendererView.swift
//  MarkdownRenderer
//
//  Created by opfic on 8/1/26.
//

import SwiftUI

public struct MarkdownRendererView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @ScaledMetric(relativeTo: .body) private var fontSize = 17

    private let markdown: String
    private let references: [Int: MarkdownRendererReference]
    private let onOpenReferenceID: ((String) -> Void)?

    public init(
        markdown: String,
        references: [Int: MarkdownRendererReference] = [:],
        onOpenReferenceID: ((String) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.references = references
        self.onOpenReferenceID = onOpenReferenceID
    }

    public var body: some View {
        MarkdownWebView(
            markdown: markdown,
            references: references,
            colorScheme: colorScheme,
            languageCode: locale.language.languageCode?.identifier ?? "und",
            fontSize: fontSize,
            onOpenReferenceID: onOpenReferenceID,
            onOpenURL: { openURL($0) }
        )
    }
}
