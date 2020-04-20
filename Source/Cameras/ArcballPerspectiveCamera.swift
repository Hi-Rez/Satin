//
//  ArcballPerspectiveCamera.swift
//  Satin
//
//  Created by Reza Ali on 9/16/19.
//

import simd

open class ArcballPerspectiveCamera: PerspectiveCamera
{
    public var arcballOrientation: simd_quatf = simd_quaternion(0, simd_make_float3(0, 0, 1))
    {
        didSet
        {
            updateViewMatrix = true
        }
    }
    
    public override var viewMatrix: matrix_float4x4
    {
        if updateViewMatrix
        {            
            _viewMatrix = simd_mul(lookAt(position, position + forwardDirection, upDirection), simd_matrix4x4(arcballOrientation))            
            updateViewMatrix = false
        }
        return _viewMatrix
    }
    
    public override init()
    {
        super.init()
        orientation = simd_quaternion(Float.pi, simd_make_float3(0, 1, 0))
        position = simd_make_float3(0.0, 0.0, 1.0)
    }
    
    public required init(from decoder: Decoder) throws
    {
        try super.init(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        arcballOrientation = try values.decode(simd_quatf.self, forKey: .arcballOrientation)
    }
    
    open override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(arcballOrientation, forKey: .arcballOrientation)
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case arcballOrientation
    }
}
