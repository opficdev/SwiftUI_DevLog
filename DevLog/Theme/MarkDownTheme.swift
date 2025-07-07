//
//  MarkDownTheme.swift
//  DevLog
//
//  Created by opfic on 7/7/25.
//

import UIKit
import Runestone

// MARK: - MarkDownTheme for Runestone
final class MarkDownTheme: Runestone.Theme {
    let font: UIFont
    var textColor: UIColor
    let tintColor: UIColor // 커서 색상을 위해 별도로 유지하는 프로퍼티

    // MARK: - Theme Protocol Requirements
    let gutterBackgroundColor: UIColor = .clear
    let gutterHairlineColor: UIColor = .clear
    let lineNumberColor: UIColor = .clear
    var lineNumberFont: UIFont {
        // 본문 폰트와 동일하게 설정
        return font
    }
    let selectedLineBackgroundColor: UIColor = UIColor.systemFill
    let selectedLinesLineNumberColor: UIColor = .clear
    let selectedLinesGutterBackgroundColor: UIColor = .clear
    let invisibleCharactersColor: UIColor = .clear
    let pageGuideHairlineColor: UIColor = .clear
    let pageGuideBackgroundColor: UIColor = .clear
    let markedTextBackgroundColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.2)

    init(font: UIFont, textColor: UIColor, tintColor: UIColor) {
        self.font = font
        self.textColor = textColor
        self.tintColor = tintColor
    }

    func textColor(for highlightName: String) -> UIColor? {
        // 구문 하이라이팅을 사용하지 않으므로 nil 반환
        return nil
    }
}
