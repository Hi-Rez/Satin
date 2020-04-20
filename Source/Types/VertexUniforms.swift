//
//  VertexUniforms.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

public struct VertexUniforms {
    public var modelMatrix: float4x4
    public var viewMatrix: float4x4
    public var modelViewMatrix: float4x4
    public var projectionMatrix: float4x4
    public var normalMatrix: float3x3
    public var worldCameraPosition: simd_float3
    public var worldCameraViewDirection: simd_float3
}
