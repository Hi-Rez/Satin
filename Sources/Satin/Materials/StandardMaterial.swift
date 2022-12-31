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

    public var metallic: Float = 1.0 {
        didSet {
            set("Metallic", metallic)
        }
    }

    public var roughness: Float = 1.0 {
        didSet {
            set("Roughness", roughness)
        }
    }

    private var maps: [PBRTexture: MTLTexture?] = [:] {
        didSet {
            if oldValue.keys != maps.keys, let shader = shader as? StandardShader {
                shader.maps = Set(maps.keys)
            }
        }
    }

    public func setTexture(_ texture: MTLTexture?, type: PBRTexture) {
        if let texture = texture {
            maps[type] = texture
        }
        else {
            maps.removeValue(forKey: type)
        }
    }

    public init(baseColor: simd_float4,
                metallic: Float,
                roughness: Float,
                specular: Float = 0.5,
                emissiveColor: simd_float4 = .zero,
                maps: [PBRTexture: MTLTexture?] = [:])
    {
        super.init()
        self.baseColor = baseColor
        self.metallic = metallic
        self.roughness = roughness
        self.emissiveColor = emissiveColor
        self.maps = maps
        self.lighting = true
        self.blending = .disabled
        initalizeParameters()
    }

    public init(maps: [PBRTexture: MTLTexture?] = [:]) {
        super.init()
        self.maps = maps
        self.lighting = true
        self.blending = .disabled
        initalizeParameters()
    }

    func initalizeParameters() {
        set("Base Color", baseColor)
        set("Emissive Color", emissiveColor)
        set("Specular", specular)
        set("Metallic", metallic)
        set("Roughness", roughness)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        self.lighting = true
        self.blending = .disabled
        initalizeParameters()
    }

    public required init() {
        super.init()
        self.lighting = true
        self.blending = .disabled
        initalizeParameters()
    }

    override open func updateShaderDefines() {
        super.updateShaderDefines()
        guard let shader = shader as? StandardShader else { return }
        shader.maps = Set(maps.keys)
    }

    override open func createShader() -> Shader {
        return StandardShader(label, getPipelinesMaterialsUrl(label)!.appendingPathComponent("Shaders.metal"))
    }

    override open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
        bindMaps(renderEncoder)
    }

    func bindMaps(_ renderEncoder: MTLRenderCommandEncoder) {
        for (index, texture) in maps where texture != nil {
            renderEncoder.setFragmentTexture(texture, index: index.rawValue)
        }
    }
}
