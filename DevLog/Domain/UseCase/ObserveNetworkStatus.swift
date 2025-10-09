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
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private(set) var isConnectedPublisher: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isConnectedPublisher = Just(path.status == .satisfied).eraseToAnyPublisher()
            }
        }
        monitor.start(queue: queue)
    }
}
