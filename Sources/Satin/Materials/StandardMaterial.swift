//
//  StandardMaterial.swift
//  Satin
//
//  Created by Reza Ali on 11/5/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import ModelIO
import simd

open class StandardMaterial: Material {
    public var baseColor: simd_float4 = .one {
        didSet {
            set("Base Color", baseColor)
        }
    }

    public var emissiveColor: simd_float4 = .zero {
        didSet {
            set("Emissive Color", emissiveColor)
        }
    }

    public var specular: Float = 0.5 {
        didSet {
            set("Specular", specular)
        }
    }

    public var metallic: Float = 0.0 {
        didSet {
            set("Metallic", metallic)
        }
    }

    public var roughness: Float = 0.0 {
        didSet {
            set("Roughness", roughness)
        }
    }

    public var environmentIntensity: Float = 1.0 {
        didSet {
            set("Environment Intensity", environmentIntensity)
        }
    }

    private var maps: [PBRTextureIndex: MTLTexture?] = [:] {
        didSet {
            if oldValue.keys != maps.keys, let shader = shader as? PBRShader {
                shader.maps = maps
            }
        }
    }

    private var samplers: [PBRTextureIndex: MTLSamplerDescriptor?] = [:] {
        didSet {
            if oldValue.keys != samplers.keys, let shader = shader as? PBRShader {
                shader.samplers = samplers
            }
        }
    }

    public func setTexture(_ texture: MTLTexture?, type: PBRTextureIndex) {
        if let texture = texture {
            maps[type] = texture
            if samplers[type] == nil {
                let sampler = MTLSamplerDescriptor()
                sampler.minFilter = .linear
                sampler.magFilter = .linear
                sampler.mipFilter = .linear
                setSampler(sampler, type: type)
            }
        } else {
            samplers.removeValue(forKey: type)
            maps.removeValue(forKey: type)
        }
    }

    public func setSampler(_ sampler: MTLSamplerDescriptor?, type: PBRTextureIndex) {
        if let sampler = sampler {
            samplers[type] = sampler
        } else {
            samplers.removeValue(forKey: type)
        }
    }

    public init(baseColor: simd_float4,
                metallic: Float,
                roughness: Float,
                specular: Float = 0.5,
                emissiveColor: simd_float4 = .zero,
                maps: [PBRTextureIndex: MTLTexture?] = [:])
    {
        super.init()
        self.baseColor = baseColor
        self.metallic = metallic
        self.roughness = roughness
        self.specular = specular
        self.emissiveColor = emissiveColor
        self.maps = maps
        lighting = true
        blending = .disabled
        initalizeParameters()
    }

    public init(maps: [PBRTextureIndex: MTLTexture?] = [:]) {
        super.init()
        self.maps = maps
        lighting = true
        blending = .disabled
        initalizeParameters()
    }

    func initalizeParameters() {
        set("Base Color", baseColor)
        set("Emissive Color", emissiveColor)
        set("Specular", specular)
        set("Metallic", metallic)
        set("Roughness", roughness)
        set("Environment Intensity", environmentIntensity)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        lighting = true
        blending = .disabled
    }

    public required init() {
        super.init()
        lighting = true
        blending = .disabled
        initalizeParameters()
    }

    override open func updateShaderDefines() {
        super.updateShaderDefines()
        guard let shader = shader as? PBRShader else { return }
        shader.maps = maps.filter { $0.value != nil }
        shader.samplers = samplers.filter { $0.value != nil }
    }

    override open func createShader() -> Shader {
        return StandardShader(label, getPipelinesMaterialsURL(label)!.appendingPathComponent("Shaders.metal"))
    }

    override open func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        super.bind(renderEncoder, shadow: shadow)
        if !shadow {
            bindMaps(renderEncoder)
        }
    }

    func bindMaps(_ renderEncoder: MTLRenderCommandEncoder) {
        for (index, texture) in maps where texture != nil {
            renderEncoder.setFragmentTexture(texture, index: index.rawValue)
        }
    }
}
