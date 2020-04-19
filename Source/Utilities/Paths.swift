//
//  Paths.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public func getResourcePath() -> String? {
    if let resourcePath = Bundle(for: BasicColorMaterial.self).resourcePath {
        return resourcePath
    }
    return nil
}

public func getResourcePath(_ path: String) -> String? {
    if let resourcePath = Bundle(for: BasicColorMaterial.self).resourcePath {
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

public func getLibraryPipelinesPath() -> String? {
    if let libraryPath = getPipelinesPath("Library") {
        return libraryPath
    }
    return nil
}

public func getLibraryPipelinesPath(_ path: String) -> String? {
    if let libraryPath = getLibraryPipelinesPath() {
        return libraryPath + "/" + path
    }
    return nil
}

public func getSatinPipelinesPath() -> String? {
    if let satinPath = getPipelinesPath("Satin") {
        return satinPath
    }
    return nil
}

public func getSatinPipelinesPath(_ path: String) -> String? {
    if let satinPath = getSatinPipelinesPath() {
        return satinPath + "/" + path
    }
    return nil
}

public func getCommonPipelinesPath() -> String? {
    if let commonPath = getPipelinesPath("Common") {
        return commonPath
    }
    return nil
}

public func getCommonPipelinesPath(_ path: String) -> String? {
    if let commonPath = getCommonPipelinesPath() {
        return commonPath + "/" + path
    }
    return nil
}

public func getMaterialsPipelinesPath() -> String? {
    if let materialsPath = getPipelinesPath("Materials") {
        return materialsPath
    }
    return nil
}

public func getMaterialsPipelinesPath(_ path: String) -> String? {
    if let materialsPath = getMaterialsPipelinesPath() {
        return materialsPath + "/" + path
    }
    return nil
}


