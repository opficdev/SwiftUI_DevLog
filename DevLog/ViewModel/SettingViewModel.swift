//
//  SettingViewModel.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

class SettingViewModel: ObservableObject {
    @Published var theme: String = ""
    @Published var appIcon: String = ""
}
