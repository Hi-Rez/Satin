//
//  Raycaster.swift
//  Satin
//
//  Created by Reza Ali on 11/29/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

public func raycast(ray: Ray, objects: [Object], recursive: Bool = true, invisible: Bool = false) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    for object in objects {
        object.intersect(
            ray: ray,
            intersections: &intersections,
            recursive: recursive,
            invisible: invisible
        )
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(origin: simd_float3, direction: simd_float3, objects: [Object], recursive: Bool = true, invisible: Bool = false) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    for object in objects {
        object.intersect(
            ray: Ray(origin: origin, direction: direction),
            intersections: &intersections,
            recursive: recursive,
            invisible: invisible
        )
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(camera: Camera, coordinate: simd_float2, objects: [Object], recursive: Bool = true, invisible: Bool = false) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    for object in objects {
        object.intersect(
            ray: Ray(camera: camera, coordinate: coordinate),
            intersections: &intersections,
            recursive: recursive,
            invisible: invisible
        )
    }
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(ray: Ray, object: Object, recursive: Bool = true, invisible: Bool = false) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    object.intersect(
        ray: ray,
        intersections: &intersections,
        recursive: recursive,
        invisible: invisible
    )
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(origin: simd_float3, direction: simd_float3, object: Object, recursive: Bool = true, invisible: Bool = false) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    object.intersect(
        ray: Ray(origin: origin, direction: direction),
        intersections: &intersections,
        recursive: recursive,
        invisible: invisible
    )
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

public func raycast(camera: Camera, coordinate: simd_float2, object: Object, recursive: Bool = true, invisible: Bool = false) -> [RaycastResult] {
    var intersections = [RaycastResult]()
    object.intersect(
        ray: Ray(camera: camera, coordinate: coordinate),
        intersections: &intersections,
        recursive: recursive,
        invisible: invisible
    )
    intersections.sort { $0.distance < $1.distance }
    return intersections
}

