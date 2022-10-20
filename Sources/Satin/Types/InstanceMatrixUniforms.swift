//
//  InstanceMatrixUniforms.swift
//  
//
//  Created by Reza Ali on 10/19/22.
//

import Foundation
import simd

public struct InstanceMatrixUniforms {
    public var modelMatrix: float4x4
    public var normalMatrix: float3x3
    
    init(modelMatrix: float4x4 = matrix_identity_float4x4, normalMatrix: float3x3 = matrix_identity_float3x3) {
        self.modelMatrix = modelMatrix
        self.normalMatrix = normalMatrix
    }
}
