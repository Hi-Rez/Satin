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

    public var gammaCorrection: Float = 1.0 {
        didSet {
            set("Gamma Correction", gammaCorrection)
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

    public var tonemapping: Tonemapping = .aces {
        didSet {
            if oldValue != tonemapping, let shader = shader as? PBRShader {
                shader.tonemapping = tonemapping
            }
        }
    }

    public func setTexture(_ texture: MTLTexture?, type: PBRTextureIndex) {
        if let texture = texture {
            maps[type] = texture
            setTextureMultiplierUniformToOne(type: type)
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

    public func setTexcoordTransform(_ transform: simd_float3x3, type: PBRTextureIndex) {
        set(type.texcoordName.titleCase, transform)
    }

    public func setTexcoordTransform(offset: simd_float2, scale: simd_float2, rotation: Float, type: PBRTextureIndex) {
        let ct = cos(rotation)
        let st = sin(rotation)

        let rotateTransform = simd_float3x3(
            simd_make_float3(ct, st, 0.0),
            simd_make_float3(-st, ct, 0.0),
            simd_make_float3(0.0, 0.0, 0.0)
        )

        let offsetTransform = simd_float3x3(
            simd_make_float3(1.0, 0.0, 0.0),
            simd_make_float3(0.0, 1.0, 0.0),
            simd_make_float3(offset.x, offset.y, 0.0)
        )

        let scaleTransform = simd_float3x3(
            simd_make_float3(scale.x, 0.0, 0.0),
            simd_make_float3(0.0, scale.y, 0.0),
            simd_make_float3(0.0, 0.0, 0.0)
        )

        let transform = rotateTransform * scaleTransform * offsetTransform
        set(type.texcoordName.titleCase, transform)
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
        initalize()
    }

    public init(maps: [PBRTextureIndex: MTLTexture?] = [:]) {
        super.init()
        self.maps = maps
        lighting = true
        blending = .disabled
        initalize()
    }

    func initalize() {
        initalizeParameters()
        initalizeTexcoordParameters()
    }

    func initalizeTexcoordParameters() {
        for type in PBRTextureIndex.allTexcoordCases {
            set(type.texcoordName.titleCase, matrix_identity_float3x3)
        }
    }

    func initalizeParameters() {
        set("Base Color", baseColor)
        set("Emissive Color", emissiveColor)
        set("Roughness", roughness)
        set("Metallic", metallic)
        set("Specular", specular)
        set("Environment Intensity", environmentIntensity)
        set("Gamma Correction", gammaCorrection)
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
        initalize()
    }

    override open func updateShaderProperties(_ shader: Shader) {
        super.updateShaderProperties(shader)
        guard let pbrShader = shader as? PBRShader else { return }
        pbrShader.maps = maps.filter { $0.value != nil }
        pbrShader.samplers = samplers.filter { $0.value != nil }
        pbrShader.tonemapping = tonemapping
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

    /// This function is called when a valid PBR texture is set.
    /// This allows users to scale the texture values by the uniform values.
    /// When this function is called, the value is set to one to ensure
    /// the texture values value aren't scaled to zero by the uniform
    internal func setTextureMultiplierUniformToOne(type: PBRTextureIndex) {
        switch type {
            case .baseColor:
                baseColor.x = 1.0
                baseColor.y = 1.0
                baseColor.z = 1.0
            case .subsurface:
                break
            case .metallic:
                metallic = 1.0
            case .roughness:
                roughness = 1.0
            case .normal:
                break
            case .emissive:
                emissiveColor = .one
            case .specular:
                specular = 1.0
            case .specularTint:
                break
            case .sheen:
                break
            case .sheenTint:
                break
            case .clearcoat:
                break
            case .clearcoatRoughness:
                break
            case .clearcoatGloss:
                break
            case .anisotropic:
                break
            case .anisotropicAngle:
                break
            case .bump:
                break
            case .displacement:
                break
            case .alpha:
                baseColor.w = 1.0
            case .ior:
                break
            case .transmission:
                break
            case .ambientOcclusion:
                break
            case .reflection:
                break
            case .irradiance:
                break
            case .brdf:
                break
        }
    }
}
