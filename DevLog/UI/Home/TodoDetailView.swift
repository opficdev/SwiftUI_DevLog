//
//  TodoDetailView.swift
//  DevLog
//
//  Created by opfic on 6/12/25.
//

import SwiftUI
import MarkdownUI

struct TodoDetailView: View {
    @EnvironmentObject var todoVM: TodoViewModel
    @State private var todo: Todo
    @State private var showEditor: Bool = false
    
    init(todo: Todo) {
        self._todo = State(initialValue: todo)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(todo.title)
                    .font(.title3)
                    .padding(.horizontal)
                if let date = todo.dueDate {
                    Divider()
                    HStack {
                        Text("마감일")
                        Spacer()
                        Text(date.formatted(date: .long, time: .omitted))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    .padding(.horizontal)
                }
                Divider()
                HStack {
                    Text("태그")
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(todo.tags, id: \.self) { tag in
                                Text(tag)
                                .padding(.horizontal, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(UIColor.systemFill))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                Divider()
                Markdown(todo.content)
                    .padding(.horizontal)
            }
        }
        .fullScreenCover(isPresented: $showEditor) {
            TodoEditorView(title: "수정", todo: todo)
                .environmentObject(todoVM)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showEditor = true
                }) {
                    Text("수정")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
