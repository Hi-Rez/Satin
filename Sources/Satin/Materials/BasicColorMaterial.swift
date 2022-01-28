//
//  BasicColorMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class BasicColorMaterial: Material {
    public init(_ color: simd_float4 = simd_float4(repeating: 1.0), _ blending: Blending = .alpha) {
        super.init()
        self.blending = blending
        createShader()
        set("Color", color)
    }
}
