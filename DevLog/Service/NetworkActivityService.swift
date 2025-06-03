//
//  NetworkActivityService.swift
//  DevLog
//
//  Created by opfic on 6/3/25.
//

import Foundation
import Combine
import Network

@MainActor
final class NetworkActivityService: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected = true   //  셀룰러 또는 와이파이 연결 상태
    @Published var showNetworkAlert = false
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isConnected = path.status == .satisfied
            
                if !self.isConnected {
                    self.showNetworkAlert = true
                }
                else {
                    self.showNetworkAlert = false
                }
            }
        }
        monitor.start(queue: queue)
    }
}
