//
//  Ray.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

import simd

public extension Ray {
    init() {
        self = Ray(origin: simd_make_float3(0.0, 0.0, 0.0), direction: simd_make_float3(0.0, 0.0, 1.0))
    }
    
    init(_ camera: Camera, _ coordinate: simd_float2 = .zero) {
        var _origin: simd_float3 = .zero
        var _direction: simd_float3 = .zero
        
        if camera is PerspectiveCamera {
            _origin = camera.worldPosition
            let unproject = camera.unProject(coordinate)
            _direction = normalize(simd_make_float3(unproject.x - _origin.x, unproject.y - _origin.y, unproject.z - _origin.z))
        }
        else {
            _origin = camera.unProject(coordinate)
            _direction = normalize(simd_make_float3(camera.worldMatrix * simd_float4(0.0, 0.0, -1.0, 0.0)))
        }
        
        self = Ray(origin: _origin, direction: _direction)
    }
    
    init(_ origin: simd_float3, _ direction: simd_float3) {
        self = Ray(origin: origin, direction: direction)
    }
    
    func at(_ t: Float) -> simd_float3 {
        return direction * t + origin
    }
}

extension Ray: Equatable {
    public static func == (lhs: Ray, rhs: Ray) -> Bool {
        return lhs.origin == rhs.origin && lhs.direction == rhs.direction
    }
}
