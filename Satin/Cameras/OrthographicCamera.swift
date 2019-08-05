//
//  OrthographicCamera.swift
//  Satin
//
//  Created by Reza Ali on 8/5/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class OrthographicCamera: Camera
{
    public var left: Float = -1.0
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }

    public var right: Float = 1.0
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }

    public var top: Float = 1.0
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }

    public var bottom: Float = -1.0
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }

    public override var projectionMatrix: matrix_float4x4
    {
        if updateProjectionMatrix
        {
            _projectionMatrix = orthographic(left: left, right: right, bottom: bottom, top: top, near: near, far: far)
            updateProjectionMatrix = false
        }
        return _projectionMatrix
    }
    
    public override init()
    {
        
    }
    
    public init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
        super.init()
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.near = near
        self.far = far
    }
}
