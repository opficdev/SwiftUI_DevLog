//
//  UIFont.swift
//  DevLog
//
//  Created by opfic on 5/31/25.
//

import SwiftUI

extension UIFont {
    static func from(font: Font) -> UIFont {
        let fontMapping: [Font: UIFont.TextStyle] = [
            .largeTitle: .largeTitle,
            .title: .title1,
            .title2: .title2,
            .title3: .title3,
            .headline: .headline,
            .subheadline: .subheadline,
            .body: .body,
            .callout: .callout,
            .footnote: .footnote,
            .caption: .caption1,
            .caption2: .caption2
        ]

        let textStyle: UIFont.TextStyle = fontMapping[font] ?? .body
        return UIFont.preferredFont(forTextStyle: textStyle)
    }
}
