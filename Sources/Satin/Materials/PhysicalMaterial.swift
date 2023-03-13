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

    override func initalizeParameters() {
        super.initalizeParameters()
        set("Subsurface", subsurface)
        set("Anisotropic", anisotropic)
        set("Specular Tint", specularTint)
        set("Anisotropic", anisotropic)
        set("Anisotropic Angle", anisotropicAngle)
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
                anisotropicAngle: Float = .zero,
                specularTint: Float = .zero,
                clearcoat: Float = .zero,
                clearcoatRoughness: Float = .zero,
                sheen: Float = .zero,
                sheenTint: Float = .zero,
                transmission: Float = .zero,
                thickness: Float = 0.0,
                ior: Float = 1.5,
                maps: [PBRTexture: MTLTexture?] = [:])
    {
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
        initalizeParameters()
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    public required init() {
        super.init()
        lighting = true
        blending = .disabled
        initalizeParameters()
    }

    override open func createShader() -> Shader {
        return PhysicalShader(label, getPipelinesMaterialsUrl(label)!.appendingPathComponent("Shaders.metal"))
    }
}

public extension PhysicalMaterial {
    convenience init(material: MDLMaterial, textureLoader: MTKTextureLoader) {
        self.init()

        // baseColor
        if let property = material.property(with: .baseColor) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .baseColor)
                }
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

        // subsurface
        if let property = material.property(with: .subsurface) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .subsurface)
                }
            } else if property.type == .float {
                subsurface = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // metallic
        if let property = material.property(with: .metallic) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .metallic)
                }
            } else if property.type == .float {
                metallic = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // specular
        if let property = material.property(with: .specular) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .specular)
                }
            } else if property.type == .float {
                specular = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // specularTint
        if let property = material.property(with: .specularTint) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .specularTint)
                }
            } else if property.type == .float {
                specularTint = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // roughness
        if let property = material.property(with: .roughness) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .roughness)
                }
            } else if property.type == .float {
                print("roughness constant: \(property.floatValue)")
                roughness = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // anisotropic
        if let property = material.property(with: .anisotropic) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .anisotropic)
                }
            } else if property.type == .float {
                anisotropic = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // anisotropicRotation
        if let property = material.property(with: .anisotropicRotation) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .anisotropicAngle)
                }
            } else if property.type == .float {
                anisotropicAngle = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // sheen
        if let property = material.property(with: .sheen) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .sheen)
                }
            } else if property.type == .float {
                sheen = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // sheenTint
        if let property = material.property(with: .sheenTint) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .sheenTint)
                }
            } else if property.type == .float {
                sheenTint = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // clearcoat
        if let property = material.property(with: .clearcoat) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .clearcoat)
                }
            } else if property.type == .float {
                clearcoat = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // clearcoatGloss
        if let property = material.property(with: .clearcoatGloss) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .clearcoatGloss)
                }
            } else if property.type == .float {
                clearcoatRoughness = 1.0 - property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // emission
        if let property = material.property(with: .emission) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .emissive)
                }
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

        // bump
        if let property = material.property(with: .bump) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: false,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .bump)
                }
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // opacity
        if let property = material.property(with: .opacity) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .alpha)
                }
            } else if property.type == .float {
                baseColor.w = property.floatValue
                if property.floatValue < 1.0 {
                    blending = .alpha
                }
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // interfaceIndexOfRefraction
        if let property = material.property(with: .interfaceIndexOfRefraction) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: true,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .ior)
                }
            } else if property.type == .float {
                ior = property.floatValue
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // objectSpaceNormal
        if let property = material.property(with: .objectSpaceNormal) {
            print("Unsupported MDLMaterial Property: \(property.name)")
        }

        // tangentSpaceNormal
        if let property = material.property(with: .tangentSpaceNormal) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: false,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .normal)
                }
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // displacement
        if let property = material.property(with: .displacement) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: false,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .displacement)
                }
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }

        // ambientOcclusion
        if let property = material.property(with: .ambientOcclusion) {
            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                if let texture = loadTexture(
                    mdlTexture,
                    loader: textureLoader,
                    options: [
                        .generateMipmaps: false,
                        .origin: MTKTextureLoader.Origin.flippedVertically,
                    ]
                ) {
                    setTexture(texture, type: .ambientOcclusion)
                }
            } else {
                print("Unsupported MDLMaterial Property: \(property.name)")
            }
        }
    }

    private func loadTexture(_ mdlTexture: MDLTexture, loader: MTKTextureLoader, options: [MTKTextureLoader.Option: Any]? = nil) -> MTLTexture? {
        return try? loader.newTexture(texture: mdlTexture, options: options)
    }
}

/*
 let validSemantics: [MDLMaterialSemantic] = [

 ]

 for semantic in semantics {
 if let materialProperty = mdlMaterial.property(with: semantic) {

 switch materialProperty.type {
 case .color:
 print("property \(materialProperty.name) is a color: \(materialProperty.color)")
 case .none:
 print("property \(materialProperty.name) is a none")
 case .string:
 print("property \(materialProperty.name) is a string: \(materialProperty.stringValue)")
 case .URL:
 print("property \(materialProperty.name) is a url: \(materialProperty.urlValue)")
 case .texture:
 print("property \(materialProperty.name) is a texture: \(materialProperty.textureSamplerValue)")
 case .float:
 print("property \(materialProperty.name) is a float: \(materialProperty.floatValue)")
 case .float2:
 print("property \(materialProperty.name) is a float2: \(materialProperty.float2Value)")
 case .float3:
 print("property \(materialProperty.name) is a float3: \(materialProperty.float3Value)")
 case .float4:
 print("property \(materialProperty.name) is a float4: \(materialProperty.float4Value)")
 case .matrix44:
 print("property \(materialProperty.name) is a matrix44: \(materialProperty.matrix4x4)")
 case .buffer:
 print("property \(materialProperty.name) is a buffer: \(materialProperty.luminance)")
 @unknown default:
 print("property \(materialProperty.name) type is unknown")
 }

 if let sourceTexture = materialProperty.textureSamplerValue?.texture {
 print("\(materialProperty.name) is a texture")
 }
 else {
 print("\(materialProperty.name) is a value: \(materialProperty.float4Value)")
 }

 }
 }
 */
