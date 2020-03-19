//
//  Vertex.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

public struct Vertex {
    public var position: simd_float4
    public var uv: simd_float2
    public var normal: simd_float3

    public init() {
        position = simd_make_float4(0.0, 0.0, 0.0, 1.0)
        uv = simd_make_float2(0.0, 0.0)
        normal = simd_make_float3(0.0, 0.0, 1.0)
    }

    public init(_ position: simd_float4, _ uv: simd_float2, _ normal: simd_float3) {
        self.position = position
        self.uv = uv
        self.normal = normal
    }
}
