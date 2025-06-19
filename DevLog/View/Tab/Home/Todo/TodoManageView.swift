//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(todoKinds) { todo in
                HStack {
                    Text(todo.localizedName)
                }
               
            }
            .environment(\.editMode, .constant(EditMode.active))
            .navigationTitle("TODO 편집")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action : {
                        dismiss()
                    }) {
                        Text("완료")
                    }
                }
            }
        }
        .environment(\.editMode, .constant(EditMode.active))    //  편집 모드 활성화 (row 우측에 line.3.horizontal 추가됨)
    }
}

#Preview {
    TodoManageView(todoKinds: .constant(TodoKind.allCases))
}
