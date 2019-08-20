//
//  PerspectiveCamera.swift
//  Satin
//
//  Created by Reza Ali on 8/15/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class PerspectiveCamera: Camera
{
    public var fov: Float = 45
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }
    
    public var aspect: Float = 1
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }
    
    public override var scale: simd_float3
    {
        didSet
        {
            updateViewMatrix = true
        }
    }
    
    public override var position: simd_float3
    {
        didSet
        {
            updateViewMatrix = true
        }
    }
    
    public override var orientation: simd_quatf
    {
        didSet
        {
            updateViewMatrix = true
        }
    }
    
    public override var projectionMatrix: matrix_float4x4
    {
        if updateProjectionMatrix
        {
            _projectionMatrix = perspective(fov: fov, aspect: aspect, near: near, far: far)
            updateProjectionMatrix = false
        }
        return _projectionMatrix
    }
    
    public override var viewMatrix: matrix_float4x4
    {
        if updateViewMatrix
        {
            _viewMatrix = lookAt(position, position + forwardDirection, upDirection)
            updateViewMatrix = false
        }
        return _viewMatrix
    }
    
    public override init()
    {
        super.init()
        orientation = simd_quaternion(Float.pi, simd_make_float3(0,1,0))
        position = simd_make_float3(0.0, 0.0, 1.0)
    }
}
