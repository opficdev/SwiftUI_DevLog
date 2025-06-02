//
//  TodoKind.swift
//  DevLog
//
//  Created by opfic on 5/29/25.
//

import SwiftUI

enum TodoKind: String, Identifiable, CaseIterable {
    case issue = "issue"              // 이슈
    case feature = "feature"        // 신규 기능
    case improvement = "improvement"// 개선/리팩터링
    case review = "review"          // 코드/문서 리뷰
    case test = "test"              // 테스트/QA
    case doc = "doc"                // 문서화
    case research = "research"      // 리서치/학습
    case etc = "etc"                // 기타

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .issue: return "exclamationmark.triangle"
        case .feature: return "sparkles"
        case .improvement: return "arrow.triangle.2.circlepath"
        case .review: return "eye"
        case .test: return "checkmark.shield"
        case .doc: return "doc.text"
        case .research: return "magnifyingglass"
        case .etc: return "ellipsis"
        }
    }
    
    var localizedName: String {
       switch self {
       case .issue: return NSLocalizedString("task_kind_issue", comment: "Task kind: Issue")
       case .feature: return NSLocalizedString("task_kind_feature", comment: "Task kind: Feature")
       case .improvement: return NSLocalizedString("task_kind_improvement", comment: "Task kind: Improvement")
       case .review: return NSLocalizedString("task_kind_review", comment: "Task kind: Review")
       case .test: return NSLocalizedString("task_kind_test", comment: "Task kind: Test")
       case .doc: return NSLocalizedString("task_kind_doc", comment: "Task kind: Documentation")
       case .research: return NSLocalizedString("task_kind_research", comment: "Task kind: Research")
       case .etc: return NSLocalizedString("task_kind_etc", comment: "Task kind: Etc")
       }
    }
    
    var color: Color {
        switch self {
            case .issue: return Color.red
            case .feature: return Color.green
            case .improvement: return Color.cyan
            case .review: return Color.orange
            case .test: return Color.purple
            case .doc: return Color.yellow
            case .research: return Color.teal
            case .etc: return Color.gray
        }
    }
}
