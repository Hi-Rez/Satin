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

    public var anisotropicAngle: Float = .zero {
        didSet {
            set("Anisotropic Angle", anisotropicAngle)
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

    public init(
        baseColor: simd_float4 = .one,
        metallic: Float = 1.0,
        roughness: Float = 1.0,
        specular: Float = 0.5,
        emissiveColor: simd_float4 = .zero,
        subsurface: Float = .zero,
        anisotropic: Float = .zero,
        anisotropicAngle: Float = .zero,
        specularTint: Float = .zero,
        clearcoat: Float = .zero,
        clearcoatRoughness: Float = .zero,
        sheen: Float = .zero,
        sheenTint: Float = .zero,
        transmission: Float = .zero,
        thickness: Float = 0.0,
        ior: Float = 1.5,
        maps: [PBRTextureIndex: MTLTexture?] = [:]
    ) {
        super.init(baseColor: baseColor, metallic: metallic, roughness: roughness, specular: specular, emissiveColor: emissiveColor, maps: maps)

        self.subsurface = subsurface
        self.anisotropic = anisotropic
        self.anisotropicAngle = anisotropicAngle
        self.specularTint = specularTint
        self.anisotropic = anisotropic
        self.clearcoat = clearcoat
        self.clearcoatRoughness = clearcoatRoughness
        self.sheen = sheen
        self.sheenTint = sheenTint
        self.transmission = transmission
        self.thickness = thickness
        self.ior = ior

        lighting = true
        blending = .disabled
        initalize()
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    public required init() {
        super.init()
        lighting = true
        blending = .disabled
        initalize()
    }

    override func initalizeParameters() {
        super.initalizeParameters()
        set("Specular Tint", specularTint)
        set("Anisotropic", anisotropic)
        set("Anisotropic Angle", anisotropicAngle)
        set("Clearcoat", clearcoat)
        set("Clearcoat Roughness", clearcoatRoughness)
        set("Subsurface", subsurface)
        set("Sheen", sheen)
        set("Sheen Tint", sheenTint)
        set("Transmission", transmission)
        set("Thickness", thickness)
        set("Ior", ior)
    }

    override open func createShader() -> Shader {
        return PhysicalShader(label, getPipelinesMaterialsURL(label)!.appendingPathComponent("Shaders.metal"))
    }
}

public extension PhysicalMaterial {
    convenience init(material: MDLMaterial, textureLoader: MTKTextureLoader) {
        self.init()

        // MARK: - BaseColor

        if let property = material.property(with: .baseColor) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .baseColor)
            } else if property.type == .color, let color = property.color, let rgba = color.components {
                baseColor = simd_make_float4(Float(rgba[0]), Float(rgba[1]), Float(rgba[2]), Float(rgba[3]))
            } else if property.type == .float4 {
                baseColor = property.float4Value
            } else if property.type == .float3 {
                baseColor = simd_make_float4(property.float3Value, 1.0)
            } else if property.type == .float {
                baseColor = simd_make_float4(property.floatValue, property.floatValue, property.floatValue, 1.0)
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Subsurface

        if let property = material.property(with: .subsurface) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .subsurface)
            } else if property.type == .float {
                subsurface = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Metallic

        if let property = material.property(with: .metallic) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .metallic)
            } else if property.type == .float {
                metallic = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Specular

        if let property = material.property(with: .specular) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .specular)
            } else if property.type == .float {
                specular = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - SpecularTint

        if let property = material.property(with: .specularTint) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .specularTint)
            } else if property.type == .float {
                specularTint = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Roughness

        if let property = material.property(with: .roughness) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .roughness)
            } else if property.type == .float {
                roughness = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Anisotropic

        if let property = material.property(with: .anisotropic) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .anisotropic)
            } else if property.type == .float {
                anisotropic = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - AnisotropicRotation

        if let property = material.property(with: .anisotropicRotation) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .anisotropicAngle)
            } else if property.type == .float {
                anisotropicAngle = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Sheen

        if let property = material.property(with: .sheen) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .sheen)
            } else if property.type == .float {
                sheen = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - SheenTint

        if let property = material.property(with: .sheenTint) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .sheenTint)
            } else if property.type == .float {
                sheenTint = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Clearcoat

        if let property = material.property(with: .clearcoat) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .clearcoat)
            } else if property.type == .float {
                clearcoat = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - ClearcoatGloss

        if let property = material.property(with: .clearcoatGloss) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .clearcoatGloss)
            } else if property.type == .float {
                clearcoatRoughness = 1.0 - property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Emission

        if let property = material.property(with: .emission) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .emissive)
            } else if property.type == .color, let color = property.color, let rgba = color.components {
                emissiveColor = simd_make_float4(Float(rgba[0]), Float(rgba[1]), Float(rgba[2]), Float(rgba[3]))
            } else if property.type == .float4 {
                emissiveColor = property.float4Value
            } else if property.type == .float3 {
                emissiveColor = simd_make_float4(property.float3Value, 1.0)
            } else if property.type == .float {
                emissiveColor = simd_make_float4(1.0, 1.0, 1.0, property.floatValue)
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Bump

        if let property = material.property(with: .bump) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: mdlTexture.mipLevelCount > 1 ? true : false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .bump)
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Opacity

        if let property = material.property(with: .opacity) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .alpha)
            } else if property.type == .float {
                baseColor.w = property.floatValue
                if property.floatValue < 1.0 {
                    blending = .alpha
                }
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - InterfaceIndexOfRefraction

        if let property = material.property(with: .interfaceIndexOfRefraction) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .ior)
            } else if property.type == .float {
                ior = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - ObjectSpaceNormal

        if let property = material.property(with: .objectSpaceNormal) {
            print("loading object space normal")
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .normal)
            } else {
                print("objectSpaceNormal not supported")
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - TangentSpaceNormal

        if let property = material.property(with: .tangentSpaceNormal) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .normal)
            }
            else if property.type == .color, let color = property.color, let rgba = color.components {
                print(simd_make_float4(Float(rgba[0]), Float(rgba[1]), Float(rgba[2]), Float(rgba[3])))
            } else if property.type == .float4 {
                print(property.float4Value)
            } else if property.type == .float3 {
                print(simd_make_float4(property.float3Value, 1.0))
            } else if property.type == .float {
                print(simd_make_float4(1.0, 1.0, 1.0, property.floatValue))
            } else {
                print("tangentSpaceNormal not supported")
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - Displacement

        if let property = material.property(with: .displacement) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                let options: [MTKTextureLoader.Option: Any] = [
                    .generateMipmaps: false,
                    .origin: MTKTextureLoader.Origin.flippedVertically,
                ]
                loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .displacement)
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // MARK: - AmbientOcclusion

        if let property = material.property(with: .ambientOcclusion),
           property.type == .texture,
           let mdlTexture = property.textureSamplerValue?.texture {
            let options: [MTKTextureLoader.Option: Any] = [
                .generateMipmaps: false,
                .origin: MTKTextureLoader.Origin.flippedVertically,
            ]
            loadTexture(loader: textureLoader, mdlTexture: mdlTexture, options: options, target: .ambientOcclusion)
        }
    }

//    func loadTextureAsync(
//        loader: MTKTextureLoader,
//        mdlTexture: MDLTexture,
//        options: [MTKTextureLoader.Option: Any],
//        target: PBRTextureIndex
//    ) {
//        loader.newTexture(texture: mdlTexture, options: options) { [weak self] texture, error in
//            if let texture = texture {
//                self?.setTexture(texture, type: target)
//            } else if let error = error {
//                print(error.localizedDescription)
//            }
//        }
//    }

    func loadTexture(
        loader: MTKTextureLoader,
        mdlTexture: MDLTexture,
        options: [MTKTextureLoader.Option: Any],
        target: PBRTextureIndex
    ) {
        do {
            let texture = try loader.newTexture(texture: mdlTexture, options: options)
            setTexture(texture, type: target)
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
