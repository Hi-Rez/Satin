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
    public var viewProjectionMatrix: float4x4
    public var modelViewProjectionMatrix: float4x4
    public var inverseModelViewProjectionMatrix: float4x4
    public var inverseViewMatrix: float4x4
    public var normalMatrix: float3x3
    public var viewport: simd_float4
    public var worldCameraPosition: simd_float3
    public var worldCameraViewDirection: simd_float3
}
