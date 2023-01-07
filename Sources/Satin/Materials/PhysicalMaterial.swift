//
//  PhysicalMaterial.swift
//  Satin
//
//  Created by Reza Ali on 01/6/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import ModelIO
import simd

open class PhysicalMaterial: StandardMaterial {
    public var subsurface: Float = .zero {
        didSet {
            set("Subsurface", subsurface)
        }
    }
    
    public var specularTint: Float = 0.0 {
        didSet {
            set("Specular Tint", specularTint)
        }
    }
    
    public var clearcoat: Float = 0.0 {
        didSet {
            set("Clearcoat", clearcoat)
        }
    }
    
    public var clearcoatRoughness: Float = 0.0 {
        didSet {
            set("Clearcoat Roughness", clearcoatRoughness)
        }
    }
    
    public var sheen: Float = 0.0 {
        didSet {
            set("Sheen", sheen)
        }
    }
    
    public var sheenTint: Float = 0.0 {
        didSet {
            set("Sheen Tint", sheenTint)
        }
    }
    
    public var transmission: Float = 0.0 {
        didSet {
            set("Transmission", transmission)
        }
    }
    
    public var ior: Float = 1.5 {
        didSet {
            set("Ior", ior)
        }
    }

    override func initalizeParameters() {
        super.initalizeParameters()
        set("Subsurface", subsurface)
        set("Specular Tint", specularTint)
        set("Clearcoat", clearcoat)
        set("Clearcoat Roughness", clearcoatRoughness)
        set("Sheen", sheen)
        set("Sheen Tint", sheenTint)
        set("Transmission", transmission)
        set("Ior", ior)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public required init() {
        super.init()
        self.lighting = true
        self.blending = .disabled
        initalizeParameters()
    }
    
    override open func createShader() -> Shader {
        return PhysicalShader(label, getPipelinesMaterialsUrl(label)!.appendingPathComponent("Shaders.metal"))
    }
}
