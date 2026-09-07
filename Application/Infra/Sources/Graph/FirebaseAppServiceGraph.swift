//
//  FirebaseAppServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class FirebaseAppServiceGraph {
    public init() { }

    @Provide
    private func makeFirebaseAppService() -> FirebaseAppService {
        FirebaseAppServiceImpl()
    }
}
