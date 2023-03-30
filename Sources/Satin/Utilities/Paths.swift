//
//  Paths.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public func getResourceURL() -> URL? {
    #if SWIFT_PACKAGE
    return Bundle.module.resourceURL
    #else
    return Bundle(for: Object.self).resourceURL
    #endif
}

public func getResourceURL(_ path: String) -> URL? {
    return getResourceURL()?.appendingPathComponent(path)
}

public func getPipelinesURL() -> URL? {
    return getResourceURL()?.appendingPathComponent("Pipelines")
}

public func getPipelinesURL(_ path: String) -> URL? {
    return getPipelinesURL()?.appendingPathComponent(path)
}

public func getPipelinesLibraryURL() -> URL? {
    return getPipelinesURL("Library")
}

public func getPipelinesChunksURL() -> URL? {
    return getPipelinesURL("Chunks")
}

public func getPipelinesChunksURL(_ path: String) -> URL? {
    return getPipelinesChunksURL()?.appendingPathComponent(path)
}

public func getPipelinesLibraryURL(_ path: String) -> URL? {
    return getPipelinesLibraryURL()?.appendingPathComponent(path)
}

public func getPipelinesSatinURL() -> URL? {
    return getPipelinesURL("Satin")
}

public func getPipelinesSatinURL(_ path: String) -> URL? {
    return getPipelinesSatinURL()?.appendingPathComponent(path)
}

public func getPipelinesCommonURL() -> URL? {
    return getPipelinesURL("Common")
}

public func getPipelinesCommonURL(_ path: String) -> URL? {
    return getPipelinesCommonURL()?.appendingPathComponent(path)
}

public func getPipelinesMaterialsURL() -> URL? {
    return getPipelinesURL("Materials")
}

public func getPipelinesMaterialsURL(_ path: String) -> URL? {
    return getPipelinesMaterialsURL()?.appendingPathComponent(path)
}

public func getPipelinesComputeURL() -> URL? {
    return getPipelinesURL("Compute")
}
