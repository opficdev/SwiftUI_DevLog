//
//  DevelopmentRecordRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct DevelopmentRecordRepositoryGraphInput {
    public let service: DevelopmentRecordService

    public init(service: DevelopmentRecordService) {
        self.service = service
    }
}

@DependencyGraph(input: DevelopmentRecordRepositoryGraphInput.self)
public final class DevelopmentRecordRepositoryGraph {
    @Provide
    private func makeDevelopmentRecordRepository() -> DevelopmentRecordRepository {
        DevelopmentRecordRepositoryImpl(service: input.service)
    }
}
