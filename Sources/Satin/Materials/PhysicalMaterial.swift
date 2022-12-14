//
//  PhysicalMaterial.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal

open class PhysicalMaterial: StandardMaterial {
    public var clearCoat: Float = 1.0 {
        didSet {
            set("Clear Coat", clearCoat)
        }
    }
    
    public var clearCoatRoughness: Float = 0.25 {
        didSet {
            set("Clear Coat Roughness", clearCoatRoughness)
        }
    }

    override func initalizeParameters() {
        super.initalizeParameters()
        set("Clear Coat", clearCoat)
        set("Clear Coat Roughness", clearCoatRoughness)
    }

    override open func createShader() -> Shader {
        return PhysicalShader(label, getPipelinesMaterialsUrl(label)!.appendingPathComponent("Shaders.metal"))
    }
}
