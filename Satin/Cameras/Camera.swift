//
//  Camera.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class Camera: Object
{
    var _viewMatrix: matrix_float4x4 = matrix_identity_float4x4
    var _projectionMatrix: matrix_float4x4 = matrix_identity_float4x4

    public var viewMatrix: matrix_float4x4
    {
        if updateViewMatrix
        {
            _viewMatrix = matrix_identity_float4x4
            updateViewMatrix = false
        }
        return _viewMatrix
    }

    public var projectionMatrix: matrix_float4x4
    {
        if updateProjectionMatrix
        {
            _projectionMatrix = matrix_identity_float4x4
            updateProjectionMatrix = false
        }
        return _projectionMatrix
    }

    public var near: Float = 0.1
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }

    public var far: Float = 1.0
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }

    var updateProjectionMatrix: Bool = true
    var updateViewMatrix: Bool = true

    public override init()
    {}
}
