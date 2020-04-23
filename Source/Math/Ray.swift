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
    
    public init(_ origin: simd_float3, _ direction: simd_float3) {
        self.origin = origin
        self.direction = direction
    }
    
    public func at(_ t: Float) -> simd_float3 {
        return direction * t + origin
    }
}

extension Ray: Equatable {
    public static func == (lhs: Ray, rhs: Ray) -> Bool {
        return lhs.origin == rhs.origin && lhs.direction == rhs.direction
    }
}
