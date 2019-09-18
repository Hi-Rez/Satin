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
    
    public var far: Float = 100.0
    {
        didSet
        {
            updateProjectionMatrix = true
        }
    }
    
    var updateProjectionMatrix: Bool = true
    var updateViewMatrix: Bool = true
    
    public override init()
    {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws
    {
        try super.init(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        near = try values.decode(Float.self, forKey: .near)
        far = try values.decode(Float.self, forKey: .far)
    }
    
    open override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(near, forKey: .near)
        try container.encode(far, forKey: .far)
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case near
        case far
    }
}
