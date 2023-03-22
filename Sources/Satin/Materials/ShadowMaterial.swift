//
//  ShadowMaterial.swift
//  Satin
//
//  Created by Reza Ali on 3/8/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import simd

open class ShadowMaterial: Material {
    public override var receiveShadow: Bool {
        didSet {
            if receiveShadow != true {
                print("ShadowMaterial's receiveShadow must be true, reverting to true")
                receiveShadow = true
            }
        }
    }

    public init(_ color: simd_float4 = simd_make_float4(0.0, 0.0, 0.0, 0.25)) {
        super.init()
        self.blending = .alpha
        set("Color", color)
        receiveShadow = true
    }

    public required init() {
        super.init()
        blending = .alpha
        set("Color", [0.0, 0.0, 0.0, 0.25])
        receiveShadow = true
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
