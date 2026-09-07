//
//  WebPageImageUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct WebPageImageUseCaseGraphInput {
    public let repository: WebPageImageRepository

    public init(repository: WebPageImageRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: WebPageImageUseCaseGraphInput.self)
public final class WebPageImageUseCaseGraph {
    @Provide
    private func makeFetchWebPageImageDirSizeUseCase() -> FetchWebPageImageDirSizeUseCase {
        FetchWebPageImageDirSizeUseCaseImpl(input.repository)
    }

    @Provide
    private func makeClearWebPageImageDirectoryUseCase() -> ClearWebPageImageDirectoryUseCase {
        ClearWebPageImageDirectoryUseCaseImpl(input.repository)
    }
}
