//
//  Ray.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

import simd

open class Ray {
    public var origin: simd_float3
    public var direction: simd_float3
    
    public init() {
        self.origin = simd_make_float3(0.0, 0.0, 0.0)
        self.direction = simd_make_float3(0.0, 0.0, 1.0)
    }
    
    public convenience init(_ camera: Camera, _ coordinate: simd_float2 = .zero) {
        self.init()
        setFromCamera(camera, coordinate)
    }
    
    public init(_ origin: simd_float3, _ direction: simd_float3) {
        self.origin = origin
        self.direction = direction
    }
    
    public func at(_ t: Float) -> simd_float3 {
        return direction * t + origin
    }
    
    public func setFromCamera(_ camera: Camera, _ coordinate: simd_float2 = .zero) {
        if camera is PerspectiveCamera {
            origin = camera.worldPosition
            let unproject = camera.unProject(coordinate)
            direction = normalize(simd_make_float3(unproject.x - origin.x, unproject.y - origin.y, unproject.z - origin.z))
        }
        else {
            origin = camera.unProject(coordinate)
            direction = normalize(simd_make_float3(camera.worldMatrix * simd_float4(0.0, 0.0, -1.0, 0.0)))
        }
    }
}

extension Ray: Equatable {
    public static func == (lhs: Ray, rhs: Ray) -> Bool {
        return lhs.origin == rhs.origin && lhs.direction == rhs.direction
    }
}
