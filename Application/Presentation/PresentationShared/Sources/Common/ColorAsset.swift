//
//  ColorAsset.swift
//  PresentationShared
//
//  Created by opfic on 9/9/26.
//

import SwiftUI

public enum ColorAsset {
    case accentColor
    case appBackground
    case border
    case danger
    case dangerContainer
    case info
    case infoContainer
    case onPrimaryContainer
    case primaryContainer
    case review
    case reviewContainer
    case success
    case successContainer
    case surface
    case surfaceSecondary
    case textPrimary
    case textSecondary
    case textTertiary
    case warning
    case warningContainer

    fileprivate var name: String {
        let name = String(describing: self)
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}

public extension Color {
    init(asset: ColorAsset) {
        self.init(asset.name, bundle: PresentationResources.bundle)
    }
}
