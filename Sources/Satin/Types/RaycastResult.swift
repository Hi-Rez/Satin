//
//  RaycastResult.swift
//  Satin
//
//  Created by Reza Ali on 11/29/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

public struct RaycastResult {
    public let barycentricCoordinates: simd_float3
    public let distance: Float
    public let normal: simd_float3
    public let position: simd_float3
    public let uv: simd_float2
    public let primitiveIndex: UInt32
    public let object: Object
    public let submesh: Submesh?
    public let instance: Int

    public init(barycentricCoordinates: simd_float3, distance: Float, normal: simd_float3, position: simd_float3, uv: simd_float2, primitiveIndex: UInt32, object: Object, submesh: Submesh?, instance: Int = 0) {
        self.barycentricCoordinates = barycentricCoordinates
        self.distance = distance
        self.normal = normal
        self.position = position
        self.uv = uv
        self.primitiveIndex = primitiveIndex
        self.object = object
        self.submesh = submesh
        self.instance = instance
    }
}
