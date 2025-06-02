//
//  TodoTask.swift
//  DevLog
//
//  Created by opfic on 5/29/25.
//

import Foundation

struct TodoInfo: Identifiable {
    let id = UUID()
    var isPinned: Bool      //  해당 할 일이 상단에 고정되어 있는지 여부
    var isCompleted: Bool   //  해당 할 일의 완료 여부
    var isChecked: Bool     //  해당 할 일의 체크 여부
    var title: String       //  할 일의 제목
    var description: String //  할 일의 설명
    var createdAt: Date     //  할 일 생성 날짜
    var updatedAt: Date     //  할 일 수정 날짜
    var dueDate: Date?      //  할 일의 마감 날짜 (선택 사항)
    var tags: [String]      //  할 일에 연결된 태그들
    var kind: TaskKind      //  할 일의 종류
}
