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

    public var anisotropic: Float = .zero {
        didSet {
            set("Anisotropic", anisotropic)
        }
    }
    
    public var specularTint: Float = .zero {
        didSet {
            set("Specular Tint", specularTint)
        }
    }

    public var clearcoat: Float = .zero {
        didSet {
            set("Clearcoat", clearcoat)
        }
    }
    
    public var clearcoatRoughness: Float = .zero {
        didSet {
            set("Clearcoat Roughness", clearcoatRoughness)
        }
    }
    
    public var sheen: Float = .zero {
        didSet {
            set("Sheen", sheen)
        }
    }
    
    public var sheenTint: Float = .zero {
        didSet {
            set("Sheen Tint", sheenTint)
        }
    }
    
    public var transmission: Float = .zero {
        didSet {
            set("Transmission", transmission)
        }
    }

    public var thickness: Float = .zero {
        didSet {
            set("Thickness", thickness)
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
        set("Anisotropic", anisotropic)
        set("Specular Tint", specularTint)
        set("Anisotropic", anisotropic)
        set("Clearcoat", clearcoat)
        set("Clearcoat Roughness", clearcoatRoughness)
        set("Sheen", sheen)
        set("Sheen Tint", sheenTint)
        set("Transmission", transmission)
        set("Thickness", thickness)
        set("Ior", ior)
    }

    public init(baseColor: simd_float4 = .one,
                         metallic: Float = 1.0,
                         roughness: Float = 1.0,
                         specular: Float = 0.5,
                         emissiveColor: simd_float4 = .zero,
                         subsurface: Float = .zero,
                         anisotropic: Float = .zero,
                         specularTint: Float = .zero,
                         clearcoat: Float = .zero,
                         clearcoatRoughness: Float = .zero,
                         sheen: Float = .zero,
                         sheenTint: Float = .zero,
                         transmission: Float = .zero,
                         thickness: Float = 0.0,
                         ior: Float = 1.5,
                         maps: [PBRTexture : MTLTexture?] = [:]) {

        super.init(baseColor: baseColor, metallic: metallic, roughness: roughness, specular: specular, emissiveColor: emissiveColor, maps: maps)

        self.subsurface = subsurface
        self.anisotropic = anisotropic
        self.specularTint = specularTint
        self.anisotropic = anisotropic
        self.clearcoat = clearcoat
        self.clearcoatRoughness = clearcoatRoughness
        self.sheen = sheen
        self.sheenTint = sheenTint
        self.transmission = transmission
        self.thickness = thickness
        self.ior = ior

        self.lighting = true
        self.blending = .disabled
        initalizeParameters()
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
