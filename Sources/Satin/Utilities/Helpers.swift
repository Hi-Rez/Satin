//
//  Helpers.swift
//  Satin
//
//  Created by Reza Ali on 11/24/20.
//

import Foundation

public func getMeshes(_ object: Object, _ recursive: Bool, _ invisible: Bool) -> [Mesh] {
    var results: [Mesh] = []
    if invisible || object.isVisible() {
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

public func getRenderables(_ object: Object, _ recursive: Bool, _ invisible: Bool) -> [Renderable] {
    var results: [Renderable] = []
    if invisible || object.isVisible() {
        if let renderable = object as? Renderable {
            results.append(renderable)
        }

        if recursive {
            for child in object.children {
                results.append(contentsOf: getRenderables(child, recursive, invisible))
            }
        }
    }
    return results
}

public func getLights(_ object: Object, _ recursive: Bool, _ invisible: Bool) -> [Light] {
    var results: [Light] = []
    if invisible || object.isVisible() {
        if let light = object as? Light {
            results.append(light)
        }

        if recursive {
            for child in object.children {
                results.append(contentsOf: getLights(child, recursive, invisible))
            }
        }
    }
    return results
}

public func getIntersectables(_ object: Object, _ recursive: Bool, _ invisible: Bool) -> [Intersectable] {
    var results: [Intersectable] = []
    if invisible || object.isVisible() {
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
