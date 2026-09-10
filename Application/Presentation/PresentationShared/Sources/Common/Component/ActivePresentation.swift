//
//  ActivePresentation.swift
//  PresentationShared
//
//  Created by opfic on 9/9/26.
//

import SwiftUI

public extension EnvironmentValues {
    var isExposableTabContentActive: Bool {
        get { self[ExposableTabContentActiveKey.self] }
        set { self[ExposableTabContentActiveKey.self] = newValue }
    }

    private struct ExposableTabContentActiveKey: EnvironmentKey {
        static let defaultValue = true
    }
}

public extension Binding where Value == Bool {
    func activePresentation(when isActive: Bool) -> Binding {
        Binding(
            get: { isActive && wrappedValue },
            set: { isPresented in
                if isActive || !isPresented {
                    wrappedValue = isPresented
                }
            }
        )
    }
}

public extension Binding {
    func activePresentation<Wrapped>(when isActive: Bool) -> Binding<Wrapped?>
    where Value == Wrapped? {
        Binding<Wrapped?>(
            get: { isActive ? wrappedValue : nil },
            set: { value in
                switch value {
                case .some:
                    if isActive {
                        wrappedValue = value
                    }
                case .none:
                    wrappedValue = nil
                }
            }
        )
    }
}
