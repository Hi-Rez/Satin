//
//  VertexUniforms.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

struct VertexUniforms {
    var modelMatrix: float4x4
    var viewMatrix: float4x4
    var modelViewMatrix: float4x4
    var projectionMatrix: float4x4
    var normalMatrix: float3x3
}
