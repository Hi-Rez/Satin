//
//  Helpers.swift
//  Satin
//
//  Created by Reza Ali on 11/24/20.
//

import Foundation

public func getMeshes(_ object: Object, _ recursive: Bool, _ invisible: Bool) -> [Mesh] {
    var results: [Mesh] = []
    if invisible || object.visible {
        if let mesh = object as? Mesh {
            results.append(mesh)
        }
        
        if recursive {
            for child in object.children {
                results.append(contentsOf: getMeshes(child, recursive, invisible))
            }
        }
    }
    return results
}


internal func getIntersectables(_ object: Object, _ recursive: Bool, _ invisible: Bool) -> [Intersectable] {
    var results: [Intersectable] = []
    if invisible || object.visible {
        if let intersectable = object as? Intersectable, intersectable.intersectable {
            results.append(intersectable)
        }
        
        if recursive {
            for child in object.children {
                results.append(contentsOf: getIntersectables(child, recursive, invisible))
            }
        }
    }
    return results
}
