//
//  AnalyticsService.swift
//  Data
//
//  Created by opfic on 5/27/26.
//

public protocol AnalyticsService {
    func trackScreenView(_ name: String)
    func trackTodoCreate()
    func trackTodoComplete()
    func trackPushOpen()
}
