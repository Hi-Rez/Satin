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
        set("Color", color)
    }

    public required init() {
        super.init()
        self.blending = .alpha
        set("Color", [1.0, 1.0, 1.0, 1.0])
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
