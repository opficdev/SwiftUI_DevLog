//
//  AppUpdateUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct AppUpdateUseCaseGraphInput {
    public let repository: AppVersionRepository

    public init(repository: AppVersionRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: AppUpdateUseCaseGraphInput.self)
public final class AppUpdateUseCaseGraph {
    @Provide
    private func makeCheckAppUpdateUseCase() -> CheckAppUpdateUseCase {
        CheckAppUpdateUseCaseImpl(input.repository)
    }
}
