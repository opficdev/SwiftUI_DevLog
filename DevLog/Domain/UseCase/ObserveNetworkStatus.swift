//
//  ObserveNetworkStatus.swift
//  DevLog
//
//  Created by 최윤진 on 10/9/25.
//

import Foundation
import Combine
import Network

final class ObserveNetworkStatus: NetworkRepository {
    private let networkPathMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "NetworkMonitor")
    private let isConnectedCurrentValueSubject: CurrentValueSubject<Bool, Never>
    
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        isConnectedCurrentValueSubject.eraseToAnyPublisher()
    }
    
    init() {
        let initialIsConnected = networkPathMonitor.currentPath.status == .satisfied
        self.isConnectedCurrentValueSubject = CurrentValueSubject<Bool, Never>(initialIsConnected)
        
        networkPathMonitor.pathUpdateHandler = { [weak self] path in
            let isConnected = (path.status == .satisfied)
            DispatchQueue.main.async {
                self?.isConnectedCurrentValueSubject.value = isConnected
            }
        }
        
        networkPathMonitor.start(queue: networkMonitorQueue)
    }
    
    deinit {
        networkPathMonitor.cancel()
    }
}
