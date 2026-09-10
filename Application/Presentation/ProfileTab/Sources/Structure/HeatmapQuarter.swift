//
//  HeatmapQuarter.swift
//  ProfileTab
//
//  Created by opfic on 3/2/26.
//

import Foundation
import Domain

public struct HeatmapQuarter: Identifiable, Hashable {
    public var id: Date { quarterStart }
    public let quarterStart: Date
    public let months: [HeatmapMonth]
}
