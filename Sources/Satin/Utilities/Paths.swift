//
//  Paths.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public func getResourcePath() -> String? {
    #if SWIFT_PACKAGE
        return Bundle.module.resourcePath
    #else
        return Bundle(for: Object.self).resourcePath
    #endif
}

public func getResourcePath(_ path: String) -> String? {
    if let resourcePath = getResourcePath() {
        return resourcePath + "/" + path
    }
    return nil
}

public func getPipelinesPath() -> String? {
    if let pipelinesPath = getResourcePath("Pipelines") {
        return pipelinesPath
    }
    return nil
}

public func getPipelinesPath(_ path: String) -> String? {
    if let pipelinesPath = getPipelinesPath() {
        return pipelinesPath + "/" + path
    }
    return nil
}

public func getPipelinesLibraryPath() -> String? {
    if let libraryPath = getPipelinesPath("Library") {
        return libraryPath
    }
    return nil
}

public func getPipelinesLibraryPath(_ path: String) -> String? {
    if let libraryPath = getPipelinesLibraryPath() {
        return libraryPath + "/" + path
    }
    return nil
}

public func getPipelinesSatinPath() -> String? {
    if let satinPath = getPipelinesPath("Satin") {
        return satinPath
    }
    return nil
}

public func getPipelinesSatinPath(_ path: String) -> String? {
    if let satinPath = getPipelinesSatinPath() {
        return satinPath + "/" + path
    }
    return nil
}

public func getPipelinesCommonPath() -> String? {
    if let commonPath = getPipelinesPath("Common") {
        return commonPath
    }
    return nil
}

public func getPipelinesCommonPath(_ path: String) -> String? {
    if let commonPath = getPipelinesCommonPath() {
        return commonPath + "/" + path
    }
    return nil
}

public func getPipelinesMaterialsPath() -> String? {
    if let materialsPath = getPipelinesPath("Materials") {
        return materialsPath
    }
    return nil
}

public func getPipelinesMaterialsPath(_ path: String) -> String? {
    if let materialsPath = getPipelinesMaterialsPath() {
        return materialsPath + "/" + path
    }
    return nil
}

// URLS

public func getResourceUrl() -> URL? {
    #if SWIFT_PACKAGE
        return Bundle.module.resourceURL
    #else
        return Bundle(for: Object.self).resourceURL
    #endif
}

public func getResourceUrl(_ path: String) -> URL? {
    return getResourceUrl()?.appendingPathComponent(path)
}

public func getPipelinesUrl() -> URL? {
    return getResourceUrl()?.appendingPathComponent("Pipelines")
}

public func getPipelinesUrl(_ path: String) -> URL? {
    return getPipelinesUrl()?.appendingPathComponent(path)
}

public func getPipelinesLibraryUrl() -> URL? {
    return getPipelinesUrl("Library")
}

public func getPipelinesLibraryUrl(_ path: String) -> URL? {
    return getPipelinesLibraryUrl()?.appendingPathComponent(path)
}

public func getPipelinesSatinUrl() -> URL? {
    return getPipelinesUrl("Satin")
}

public func getPipelinesSatinUrl(_ path: String) -> URL? {
    return getPipelinesSatinUrl()?.appendingPathComponent(path)
}

public func getPipelinesCommonUrl() -> URL? {
    return getPipelinesUrl("Common")
}

public func getPipelinesCommonUrl(_ path: String) -> URL? {
    return getPipelinesCommonUrl()?.appendingPathComponent(path)
}

public func getPipelinesMaterialsUrl() -> URL? {
    return getPipelinesUrl("Materials")
}

public func getPipelinesComputeUrl() -> URL? {
    return getPipelinesUrl("Compute")
}

public func getPipelinesMaterialsUrl(_ path: String) -> URL? {
    return getPipelinesMaterialsUrl()?.appendingPathComponent(path)
}
