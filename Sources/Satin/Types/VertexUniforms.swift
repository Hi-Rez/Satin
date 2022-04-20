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
    public var modelViewProjectionMatrix: float4x4
    public var inverseModelViewProjectionMatrix: float4x4
    public var inverseViewMatrix: float4x4
    public var normalMatrix: float3x3
    public var viewport: simd_float4
    public var worldCameraPosition: simd_float3
    public var worldCameraViewDirection: simd_float3
}

public func createVertexUniformParameters() -> ParameterGroup {
    let parameters = ParameterGroup("VertexUniforms")
    parameters.append(Float4x4Parameter("Model Matrix", matrix_identity_float4x4, .none))
    parameters.append(Float4x4Parameter("View Matrix", matrix_identity_float4x4, .none))
    parameters.append(Float4x4Parameter("Model View Matrix", matrix_identity_float4x4, .none))
    parameters.append(Float4x4Parameter("Projection Matrix", matrix_identity_float4x4, .none))
    parameters.append(Float4x4Parameter("Model View Projection Matrix", matrix_identity_float4x4, .none))
    parameters.append(Float4x4Parameter("Inverse Model View Projection Matrix", matrix_identity_float4x4, .none))
    parameters.append(Float4x4Parameter("Inverse View Matrix", matrix_identity_float4x4, .none))
    parameters.append(Float3x3Parameter("Normal Matrix", matrix_identity_float3x3, .none))
    parameters.append(Float4Parameter("Viewport", .zero, .none))
    parameters.append(Float3Parameter("World Camera Position", .zero, .none))
    parameters.append(Float3Parameter("World Camera View Direction", .zero, .none))
    return parameters
}


