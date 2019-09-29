//
//  Paths.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public func getResourcePath() -> String?
{
    if let resourcePath = Bundle(for: BasicColorMaterial.self).resourcePath {
        return resourcePath
    }
    return nil
}

public func getResourcePath(_ path: String) -> String?
{
    if let resourcePath = Bundle(for: BasicColorMaterial.self).resourcePath {
        return resourcePath + "/" + path
    }
    return nil
}


public func getPipelinesPath() -> String?
{
    if let pipelinesPath = getResourcePath("Pipelines") {
        return pipelinesPath
    }
    return nil
}

public func getPipelinesPath(_ path: String) -> String?
{
    if let pipelinesPath = getPipelinesPath() {
        return pipelinesPath + "/" + path
    }
    return nil
}
