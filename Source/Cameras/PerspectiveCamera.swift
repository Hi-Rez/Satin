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
            updateMatrix = true
        }
    }
    
    public override var position: simd_float3
    {
        didSet
        {
            updateViewMatrix = true
            updateMatrix = true
        }
    }
    
    public override var orientation: simd_quatf
    {
        didSet
        {
            updateViewMatrix = true
            updateMatrix = true
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
            _viewMatrix = worldMatrix.inverse
            updateViewMatrix = false
        }
        return _viewMatrix
    }
    
    public override init()
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
    
    open override func encode(to encoder: Encoder) throws
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
}
