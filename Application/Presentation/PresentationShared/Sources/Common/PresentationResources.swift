//
//  PresentationResources.swift
//  PresentationShared
//
//  Created by opfic on 9/9/26.
//

import Foundation

public enum PresentationResources {
    public static let bundle = Bundle(for: PresentationResourceBundleToken.self)
}

private final class PresentationResourceBundleToken {}
