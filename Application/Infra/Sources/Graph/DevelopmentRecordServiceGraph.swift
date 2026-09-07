//
//  DevelopmentRecordServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class DevelopmentRecordServiceGraph {
    public init() { }

    @Provide
    private func makeDevelopmentRecordService() -> DevelopmentRecordService {
        DevelopmentRecordServiceImpl()
    }
}
