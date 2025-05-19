//
//  SettingViewModel.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import UIKit

class SettingViewModel: ObservableObject {
    @Published var signOutAlert = false
    @Published var deleteUserAlert = false
    @Published var theme: String = ""
    @Published var appIcon: String = ""
    
    @MainActor
    func setAppIcon(iconName: String? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    continuation.resume()
                }
            }
        }
    }
}
