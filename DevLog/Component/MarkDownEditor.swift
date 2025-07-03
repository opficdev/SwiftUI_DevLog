//
//  MarkDownEditor.swift
//  DevLog
//
//  Created by opfic on 6/28/25.
//

import SwiftUI
import Runestone

struct MarkdownEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    
    func makeUIView(context: Context) -> TextView {
        let textView = TextView()
        
        // 기본 설정
        textView.backgroundColor = UIColor.systemBackground
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        
        // 마크다운 문법 하이라이팅 설정
        textView.editorDelegate = context.coordinator
        
        // 초기 텍스트 설정
        textView.text = text.isEmpty ? placeholder : text
        
        return textView
    }
    
    func updateUIView(_ uiView: TextView, context: Context) {
        DispatchQueue.main.async {
            // 텍스트 동기화 (플레이스홀더가 아닐 때만)
            if uiView.text != self.text && uiView.text != self.placeholder {
                uiView.text = self.text
            }
            
            // 포커스 상태 동기화
            if self.isFocused && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
            else if !self.isFocused && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, TextViewDelegate {
        var parent: MarkdownEditor
        private var isShowingPlaceholder = false
        
        init(_ parent: MarkdownEditor) {
            self.parent = parent
            super.init()
            // 초기 플레이스홀더 상태 설정
            self.isShowingPlaceholder = parent.text.isEmpty
        }
        
        func textViewDidBeginEditing(_ textView: TextView) {
            DispatchQueue.main.async {
                if self.parent.isFocused != true {
                    self.parent.isFocused = true
                }
            }
            
            // 플레이스홀더 상태면 지우기
            if isShowingPlaceholder {
                textView.text = ""
                isShowingPlaceholder = false
            }
        }

        func textViewDidEndEditing(_ textView: TextView) {
            DispatchQueue.main.async {
                if self.parent.isFocused != false {
                    self.parent.isFocused = false
                }
            }
            
            // 텍스트가 비어있으면 플레이스홀더 표시
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                isShowingPlaceholder = true
            }
        }
        
        func textViewDidChange(_ textView: TextView) {
            // 플레이스홀더가 아닐 때만 바인딩 업데이트
            if !isShowingPlaceholder {
                parent.text = textView.text
            }
        }
    }
}
