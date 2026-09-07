//
//  ProfileImageDataServiceGraph.swift
//  Infra
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Data

@DependencyGraph
public final class ProfileImageDataServiceGraph {
    public init() { }

    @Provide
    private func makeProfileImageDataService() -> ProfileImageDataService {
        ProfileImageDataServiceImpl()
    }
}
