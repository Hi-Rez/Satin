//
//  FragmentFunction.swift
//  
//
//  Created by Reza Ali on 3/17/23.
//

import Foundation

public enum FragmentConstantIndex: Int {
    case Custom0 = 0
}

public enum FragmentBufferIndex: Int {
    case MaterialUniforms = 0
    case Lighting = 1
    case Shadows = 2
    case ShadowData = 3
    case Custom0 = 4
    case Custom1 = 5
    case Custom2 = 6
    case Custom3 = 7
    case Custom4 = 8
    case Custom5 = 9
    case Custom6 = 10
    case Custom7 = 11
    case Custom8 = 12
    case Custom9 = 13
    case Custom10 = 14
}

public enum FragmentTextureIndex: Int {
    case Custom0 = 0
    case Custom1 = 1
    case Custom2 = 2
    case Custom3 = 3
    case Custom4 = 4
    case Custom5 = 5
    case Custom6 = 6
    case Custom7 = 7
    case Custom8 = 8
    case Custom9 = 9
    case Custom10 = 10
    case Custom11 = 11
    case Custom12 = 12
    case Custom13 = 13
    case Custom14 = 14
    case Custom15 = 15
    case Custom16 = 16
    case Custom17 = 17
    case Custom18 = 18
    case Custom19 = 19
    case Custom20 = 20
    case Custom21 = 21
    case Custom22 = 22
    case Custom23 = 23
    case Custom24 = 24
    case Shadow0 = 25
    case Shadow1 = 26
    case Shadow2 = 27
    case Shadow3 = 28
    case Shadow4 = 29
    case Shadow5 = 30
    case Shadow6 = 31
    case Shadow7 = 32
}

public enum PBRTexture: Int {
    case baseColor = 0
    case subsurface = 1
    case metallic = 2
    case roughness = 3
    case normal = 4
    case emissive = 5
    case specular = 6
    case specularTint = 7
    case sheen = 8
    case sheenTint = 9
    case clearcoat = 10
    case clearcoatRoughness = 11
    case clearcoatGloss = 12
    case anisotropic = 13
    case anisotropicAngle = 14
    case bump = 15
    case displacement = 16
    case alpha = 17
    case ior = 18
    case transmission = 19
    case ambientOcclusion = 20
    case reflection = 21
    case irradiance = 22
    case brdf = 23

    public var shaderDefine: String {
        switch self {
            case .baseColor:
                return "BASE_COLOR_MAP"
            case .metallic:
                return "METALLIC_MAP"
            case .roughness:
                return "ROUGHNESS_MAP"
            case .normal:
                return "NORMAL_MAP"
            case .emissive:
                return "EMISSIVE_MAP"
            case .specular:
                return "SPECULAR_MAP"
            case .sheen:
                return "SHEEN_MAP"
            case .anisotropic:
                return "ANISOTROPIC_MAP"
            case .anisotropicAngle:
                return "ANISOTROPIC_ANGLE_MAP"
            case .bump:
                return "BUMP_MAP"
            case .displacement:
                return "DISPLACEMENT_MAP"
            case .alpha:
                return "ALPHA_MAP"
            case .transmission:
                return "TRANSMISSION_MAP"
            case .ambientOcclusion:
                return "AMBIENT_OCCLUSION_MAP"
            case .reflection:
                return "REFLECTION_MAP"
            case .irradiance:
                return "IRRADIANCE_MAP"
            case .brdf:
                return "BRDF_MAP"
            case .subsurface:
                return "SUBSURFACE_MAP"
            case .specularTint:
                return "SPECULAR_TINT_MAP"
            case .sheenTint:
                return "SHEEN_TINT_MAP"
            case .clearcoat:
                return "CLEARCOAT_MAP"
            case .clearcoatRoughness:
                return "CLEARCOAT_ROUGHNESS_MAP"
            case .clearcoatGloss:
                return "CLEARCOAT_GLOSS_MAP"
            case .ior:
                return "IOR_MAP"
        }
    }

    public var textureType: String {
        switch self {
            case .irradiance, .reflection:
                return "texturecube"
            default:
                return "texture2d"
        }
    }

    public var textureName: String {
        switch self {
            case .baseColor:
                return "baseColorMap"
            case .metallic:
                return "metallicMap"
            case .roughness:
                return "roughnessMap"
            case .normal:
                return "normalMap"
            case .emissive:
                return "emissiveMap"
            case .specular:
                return "specularMap"
            case .sheen:
                return "sheenMap"
            case .anisotropic:
                return "anisotropicMap"
            case .anisotropicAngle:
                return "anisotropicAngleMap"
            case .bump:
                return "bumpMap"
            case .displacement:
                return "displacementMap"
            case .alpha:
                return "alphaMap"
            case .transmission:
                return "transmissionMap"
            case .ambientOcclusion:
                return "ambientOcclusionMap"
            case .reflection:
                return "reflectionMap"
            case .irradiance:
                return "irradianceMap"
            case .brdf:
                return "brdfMap"
            case .subsurface:
                return "subsurfaceMap"
            case .specularTint:
                return "specularMap"
            case .sheenTint:
                return "sheenTintMap"
            case .clearcoat:
                return "clearcoatMap"
            case .clearcoatRoughness:
                return "clearcoatRoughnessMap"
            case .clearcoatGloss:
                return "clearcoatGlossMap"
            case .ior:
                return "iorMap"
        }
    }

    public var textureIndex: String {
        switch self {
            case .baseColor:
                return "PBRTextureBaseColor"
            case .metallic:
                return "PBRTextureMetallic"
            case .roughness:
                return "PBRTextureRoughness"
            case .normal:
                return "PBRTextureNormal"
            case .emissive:
                return "PBRTextureEmissive"
            case .specular:
                return "PBRTextureSpecular"
            case .sheen:
                return "PBRTextureSheen"
            case .anisotropic:
                return "PBRTextureAnisotropic"
            case .anisotropicAngle:
                return "PBRTextureAnisotropicAngle"
            case .bump:
                return "PBRTextureBump"
            case .displacement:
                return "PBRTextureDisplacement"
            case .alpha:
                return "PBRTextureAlpha"
            case .transmission:
                return "PBRTextureTransmission"
            case .ambientOcclusion:
                return "PBRTextureAmbientOcclusion"
            case .reflection:
                return "PBRTextureReflection"
            case .irradiance:
                return "PBRTextureIrradiance"
            case .brdf:
                return "PBRTextureBRDF"
            case .subsurface:
                return "PBRTextureSubsurface"
            case .specularTint:
                return "PBRTextureSpecularTint"
            case .sheenTint:
                return "PBRTextureSheenTint"
            case .clearcoat:
                return "PBRTextureClearcoat"
            case .clearcoatRoughness:
                return "PBRTextureClearcoatRoughness"
            case .clearcoatGloss:
                return "PBRTextureGlossRoughness"
            case .ior:
                return "PBRTextureIor"
        }
    }
}

public enum FragmentSamplerIndex: Int {
    case Custom0 = 0
    case Custom1 = 1
    case Custom2 = 2
    case Custom3 = 3
    case Custom4 = 4
    case Custom5 = 5
    case Custom6 = 6
    case Custom7 = 7
    case Custom8 = 8
    case Custom9 = 9
    case Custom10 = 10
    case Custom11 = 11
    case Custom12 = 12
    case Custom13 = 13
    case Custom14 = 14
    case Custom15 = 15
    case Custom16 = 16
    case Custom17 = 17
    case Custom18 = 18
    case Custom19 = 19
    case Custom20 = 20
    case Custom21 = 21
    case Custom22 = 22
    case Custom23 = 23
    case Custom24 = 24
    case Shadow0 = 25
    case Shadow1 = 26
    case Shadow2 = 27
    case Shadow3 = 28
    case Shadow4 = 29
    case Shadow5 = 30
    case Shadow6 = 31
    case Shadow7 = 32
}

public enum PBRSamplerIndex: Int {
    case baseColor = 0
    case subsurface = 1
    case metallic = 2
    case roughness = 3
    case normal = 4
    case emissive = 5
    case specular = 6
    case specularTint = 7
    case sheen = 8
    case sheenTint = 9
    case clearcoat = 10
    case clearcoatRoughness = 11
    case clearcoatGloss = 12
    case anisotropic = 13
    case anisotropicAngle = 14
    case bump = 15
    case displacement = 16
    case alpha = 17
    case ior = 18
    case transmission = 19
    case ambientOcclusion = 20
    case reflection = 21
    case irradiance = 22
    case brdf = 23
}

