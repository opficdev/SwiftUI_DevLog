//
//  AppVersionRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct AppVersionRepositoryGraphInput {
    public let service: AppStoreVersionService

    public init(service: AppStoreVersionService) {
        self.service = service
    }
}

@DependencyGraph(input: AppVersionRepositoryGraphInput.self)
public final class AppVersionRepositoryGraph {
    @Provide
    private func makeAppVersionRepository() -> AppVersionRepository {
        AppVersionRepositoryImpl(service: input.service)
    }
}
