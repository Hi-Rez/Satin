//
//  BasicPointMaterial.swift
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

import Metal
import simd

open class BasicPointMaterial: Material {
    public init(_ color: simd_float4 = simd_float4(repeating: 1.0), _ size: Float = 2.0, _ blending: Blending = .alpha) {
        super.init()
        self.blending = blending
        createShader()
        set("Color", color)
        set("Point Size", size)
    }
}
