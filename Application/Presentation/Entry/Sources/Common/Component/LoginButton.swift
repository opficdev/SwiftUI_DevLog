//
//  LoginButton.swift
//  Entry
//
//  Created by opfic on 4/25/25.
//

import SwiftUI

struct LoginButton: View {
    @ScaledMetric(relativeTo: .body) private var height = CGFloat(22)
    private var logo: Image?
    private var text = ""
    private let showsProgressView: Bool
    private let action: () -> Void

    init(
        logo: Image? = nil,
        text: String = "",
        showsProgressView: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.logo = logo
        self.text = text
        self.showsProgressView = showsProgressView
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            Group {
                if showsProgressView {
                    ProgressView()
                        .tint(Color(asset: .accentColor))
                } else {
                    Text(text)
                        .foregroundStyle(Color(asset: .textPrimary))
                }
            }
            .font(.system(.body))
            .contentShape(.rect(cornerRadius: 12))
            .frame(width: 300, height: height + 24)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(asset: .border), lineWidth: 3)
                    .fill(Color(asset: .surface))
            }
            .overlay(alignment: .leading) {
                if let logo, !showsProgressView {
                    logo
                        .resizable()
                        .scaledToFit()
                        .frame(width: height, height: height)
                        .padding(.leading)
                }
            }
        }
    }
}
