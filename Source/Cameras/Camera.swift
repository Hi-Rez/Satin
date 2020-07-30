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
    
    public var viewDirection: simd_float3
    {
        let v = worldMatrix
        return normalize(simd_make_float3(v.columns.0.z, v.columns.1.z, -v.columns.2.z))
    }
    
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
    
    public var near: Float = 0.01
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
    
    override var updateMatrix: Bool
    {
        didSet
        {
            updateViewMatrix = true
        }
    }
    
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
    
    // Projects a coordinate from world space into the camera's normalized device coordinate (NDC) space.
    
    open func project(_ worldCoordinate: simd_float3) -> simd_float2
    {
        var wc = simd_make_float4(worldCoordinate, 1.0)
        wc = projectionMatrix * viewMatrix * wc
        return simd_make_float2(wc) / wc.w
    }
    
    // Projects a point from world space into the camera's normalized device coordinate (NDC) space.
    
    open func project(_ worldCoordinate: simd_float3, _ viewSize: simd_float2) -> simd_float2
    {
        return viewSize * ((project(worldCoordinate) + 1.0) * 0.5)
    }
    
    // Projects a point from the camera's normalized device coordinate (NDC) space into world space.
    open func unProject(_ ndcCoordinate: simd_float2) -> simd_float3
    {
        let origin = worldMatrix * projectionMatrix.inverse * simd_float4(ndcCoordinate.x, ndcCoordinate.y, 0.5, 1.0)
        return simd_make_float3(origin)
    }
}
