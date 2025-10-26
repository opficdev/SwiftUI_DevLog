//
//  NetworkRepository.swift
//  DevLog
//
//  Created by 최윤진 on 10/7/25.
//

import Foundation
import Combine

protocol NetworkRepository {
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
}
