//
//  ArcballPerspectiveCamera.swift
//  Satin
//
//  Created by Reza Ali on 9/16/19.
//

import simd

open class ArcballPerspectiveCamera: PerspectiveCamera
{
    public var arcballOrientation: simd_quatf = simd_quatf(matrix_identity_float4x4)
    {
        didSet
        {
            updateViewMatrix = true
            updateMatrix = true
        }
    }
    
    public override var worldMatrix: matrix_float4x4
    {
        if updateMatrix
        {
            if let parent = self.parent
            {
                _worldMatrix = simd_mul(parent.worldMatrix, localMatrix)
            }
            else
            {
                _worldMatrix = localMatrix
            }
            _worldMatrix = simd_mul(simd_matrix4x4(arcballOrientation), _worldMatrix)
            updateMatrix = false
        }
        return _worldMatrix
    }
    
    public override init()
    {
        super.init()
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
