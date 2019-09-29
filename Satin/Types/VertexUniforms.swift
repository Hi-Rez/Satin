//
//  VertexUniforms.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

struct VertexUniforms {
    var modelMatrix: matrix_float4x4
    var viewMatrix: matrix_float4x4
    var modelViewMatrix: matrix_float4x4
    var projectionMatrix: matrix_float4x4
    var normalMatrix: matrix_float3x3
}
