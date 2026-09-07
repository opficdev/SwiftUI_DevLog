//
//  AppUpdateGraphSet.swift
//  App
//
//  Created by opfic on 9/7/26.
//

import Data
import Domain
import Infra

final class AppUpdateGraphSet {
    let appVersionRepositoryGraph: AppVersionRepositoryGraph
    let appUpdateUseCaseGraph: AppUpdateUseCaseGraph

    init(appStoreVersionServiceGraph: AppStoreVersionServiceGraph) {
        self.appVersionRepositoryGraph = AppVersionRepositoryGraph(
            input: AppVersionRepositoryGraphInput(
                service: appStoreVersionServiceGraph.appStoreVersionService
            )
        )
        self.appUpdateUseCaseGraph = AppUpdateUseCaseGraph(
            input: AppUpdateUseCaseGraphInput(
                repository: appVersionRepositoryGraph.appVersionRepository
            )
        )
    }
}
