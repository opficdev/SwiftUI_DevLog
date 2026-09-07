//
//  WebPageUseCaseGraph.swift
//  Domain
//
//  Created by opfic on 9/7/26.
//

import Cradle

public struct WebPageUseCaseGraphInput {
    public let repository: WebPageRepository

    public init(repository: WebPageRepository) {
        self.repository = repository
    }
}

@DependencyGraph(input: WebPageUseCaseGraphInput.self)
public final class WebPageUseCaseGraph {
    @Provide
    private func makeFetchWebPagesUseCase() -> FetchWebPagesUseCase {
        FetchWebPagesUseCaseImpl(input.repository)
    }

    @Provide
    private func makeAddWebPageUseCase() -> AddWebPageUseCase {
        AddWebPageUseCaseImpl(input.repository)
    }

    @Provide
    private func makeDeleteWebPageUseCase() -> DeleteWebPageUseCase {
        DeleteWebPageUseCaseImpl(input.repository)
    }

    @Provide
    private func makeUndoDeleteWebPageUseCase() -> UndoDeleteWebPageUseCase {
        UndoDeleteWebPageUseCaseImpl(input.repository)
    }
}
