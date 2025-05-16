//
//  LoadingView.swift
//  DevLog
//
//  Created by opfic on 5/16/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.7).ignoresSafeArea()
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
