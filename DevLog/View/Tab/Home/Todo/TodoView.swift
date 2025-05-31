//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @State private var kind: TaskKind
    
    init(_ kind: TaskKind) {
        self._kind = State(initialValue: kind)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                switch kind {
                case .issue: IssueView()
                case .feature: FeatureView()
                case .improvement: ImprovementView()
                case .review: ReviewView()
                case .test: TestView()
                case .doc: DocumentView()
                case .research: ResearchView()
                case .etc: EtcView()
                }
            }
            .navigationTitle(kind.localizedName)
        }
    }
}
