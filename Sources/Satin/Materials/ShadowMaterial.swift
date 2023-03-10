//
//  ShadowMaterial.swift
//  Satin
//
//  Created by Reza Ali on 3/8/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import simd

open class ShadowMaterial: Material {
    public init(_ color: simd_float4 = simd_make_float4(0.0, 0.0, 0.0, 0.25)) {
        super.init()
        self.blending = .alpha
        set("Color", color)
    }

    public required init() {
        super.init()
        blending = .alpha
        set("Color", [0.0, 0.0, 0.0, 0.25])
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
