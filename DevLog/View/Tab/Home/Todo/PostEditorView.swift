//
//  PostEditorView.swift
//  DevLog
//
//  Created by opfic on 5/31/25.
//

import SwiftUI

struct PostEditorView: View {
    @Environment(\.dismiss) private var dismiss
    private var navigationTitle: String
    @State private var title: String = ""
    @State private var dueDate: Date? = nil
    @State private var content: String = ""
    @State private var isFocused: Bool = false
    
    init(_ title: String) {
        self.navigationTitle = title
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    TextField("제목", text: $title)
                        .font(.title3)
                        .padding(.horizontal)
                    Divider()
                    DatePicker("마감일", selection: Binding<Date>(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                    Divider()
                    UIKitTextEditor(text: $content, isFocused: $isFocused, placeholder: "내용을 입력하세요.")
                        .padding(.horizontal)
                }
            }
            .listStyle(.plain)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task {
                            
                            dismiss()
                        }
                    }) {
                        Text("추가")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }
}

#Preview {
    PostEditorView("")
}
