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
    
    override public var scale: simd_float3
    {
        didSet
        {
            updateViewMatrix = true
            updateMatrix = true
        }
    }
    
    override public var position: simd_float3
    {
        didSet
        {
            updateViewMatrix = true
            updateMatrix = true
        }
    }
    
    override public var orientation: simd_quatf
    {
        didSet
        {
            updateViewMatrix = true
            updateMatrix = true
        }
    }
    
    override public var projectionMatrix: matrix_float4x4
    {
        get
        {
            if updateProjectionMatrix
            {
                _projectionMatrix = perspectiveMatrixf(fov, aspect, near, far)
                updateProjectionMatrix = false
            }
            return _projectionMatrix
        }
        set
        {
            _projectionMatrix = newValue
            let col0 = newValue.columns.0
            let col1 = newValue.columns.1
            let col2 = newValue.columns.2
            let col3 = newValue.columns.3
            fov = radToDeg(2.0 * atan(1.0 / col1.y))
            aspect = col1.y / col0.x
            let c = col2.z
            let d = col3.z
            near = d / c
            far = d / (1.0 + c)
        }
    }
    
    override public var viewMatrix: matrix_float4x4
    {
        get
        {
            if updateViewMatrix
            {
                _viewMatrix = worldMatrix.inverse
                updateViewMatrix = false
            }
            return _viewMatrix
        }
        set
        {
            _viewMatrix = newValue
            localMatrix = newValue.inverse
        }
    }
    
    public convenience init(position: simd_float3, near: Float, far: Float, fov: Float = 45)
    {
        self.init()
        self.position = position
        self.near = near
        self.far = far
        self.fov = fov
    }
    
    override public init()
    {
        super.init()
        orientation = simd_quatf(matrix_identity_float4x4)
        position = simd_make_float3(0.0, 0.0, 1.0)
    }
    
    public required init(from decoder: Decoder) throws
    {
        try super.init(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fov = try values.decode(Float.self, forKey: .fov)
        aspect = try values.decode(Float.self, forKey: .aspect)
    }
    
    override open func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fov, forKey: .fov)
        try container.encode(aspect, forKey: .aspect)
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case fov
        case aspect
    }
    
    // Projects a point from the camera's normalized device coordinate (NDC) space into world space, the returned point is at a distance equal to the near property of the camera
    override open func unProject(_ ndcCoordinate: simd_float2) -> simd_float3
    {
        let farMinusNear = far - near
        let wc = worldMatrix * projectionMatrix.inverse * simd_make_float4(ndcCoordinate.x, ndcCoordinate.y, near / farMinusNear, 1.0)
        return simd_make_float3(wc) / wc.w
    }
    
    override public func setFrom(_ object: Object)
    {
        super.setFrom(object)
        if let camera = object as? PerspectiveCamera
        {
            fov = camera.fov
            aspect = camera.aspect
        }
    }
}
