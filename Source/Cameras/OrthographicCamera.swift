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
        left = -1
        right = 1
        bottom = -1
        top = 1
        near = -1
        far = 1
    }
    
    public init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float)
    {
        super.init()
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.near = near
        self.far = far
    }
    
    public func update(left: Float, right: Float, bottom: Float, top: Float)
    {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
    }
    
    public func update(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float)
    {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.near = near
        self.far = far
    }
    
    public required init(from decoder: Decoder) throws
    {
        try super.init(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        left = try values.decode(Float.self, forKey: .left)
        right = try values.decode(Float.self, forKey: .right)
        bottom = try values.decode(Float.self, forKey: .bottom)
        top = try values.decode(Float.self, forKey: .top)
        near = try values.decode(Float.self, forKey: .near)
        far = try values.decode(Float.self, forKey: .far)
    }
    
    open override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(left, forKey: .left)
        try container.encode(right, forKey: .right)
        try container.encode(bottom, forKey: .bottom)
        try container.encode(top, forKey: .top)
        try container.encode(near, forKey: .near)
        try container.encode(far, forKey: .far)
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case left
        case right
        case bottom
        case top
        case near
        case far
    }
}
