//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @Binding var todoKinds: [TodoKind]
    
    var body: some View {
        List {
            ForEach(todoKinds) { todo in
                HStack {
                    Text(todo.localizedName)
                }
               
            }
            .onMove { (source: IndexSet, destination: Int) in
                todoKinds.move(fromOffsets: source, toOffset: destination)
            }
        }
        .environment(\.editMode, .constant(EditMode.active))    //  편집 모드 활성화 (row 우측에 line.3.horizontal 추가됨)
    }
}

#Preview {
    TodoManageView(todoKinds: .constant(TodoKind.allCases))
}
