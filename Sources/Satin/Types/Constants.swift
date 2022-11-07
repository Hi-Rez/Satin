//
//  Defines.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

public let maxBuffersInFlight: Int = 3

public let worldForwardDirection = simd_make_float3(0, 0, 1)
public let worldUpDirection = simd_make_float3(0, 1, 0)
public let worldRightDirection = simd_make_float3(1, 0, 0)

public enum Blending: Codable {
    case disabled
    case alpha
    case additive
    case subtract
    case custom
}

public enum LightType: Int  {
    case ambient = 0
    case directional = 1
    case point = 2
    case spot = 3
}

public enum VertexAttribute: Int {
    case Position = 0
    case Normal = 1
    case Texcoord = 2
    case Tangent = 3
    case Bitangent = 4
    case Custom0 = 5
    case Custom1 = 6
    case Custom2 = 7
    case Custom3 = 8
    case Custom4 = 9
    case Custom5 = 10
    case Custom6 = 11
    case Custom7 = 12
    case Custom8 = 13
    case Custom9 = 14
    case Custom10 = 15
    case Custom11 = 16

    public var description: String {
        return String(describing: self)
    }

    public var name: String {
        switch self {
        case .Position:
            return "position"
        case .Normal:
            return "normal"
        case .Texcoord:
            return "uv"
        case .Tangent:
            return "tangent"
        case .Bitangent:
            return "bitangent"
        case .Custom0:
            return "custom0"
        case .Custom1:
            return "custom1"
        case .Custom2:
            return "custom2"
        case .Custom3:
            return "custom3"
        case .Custom4:
            return "custom4"
        case .Custom5:
            return "custom5"
        case .Custom6:
            return "custom6"
        case .Custom7:
            return "custom7"
        case .Custom8:
            return "custom8"
        case .Custom9:
            return "custom9"
        case .Custom10:
            return "custom10"
        case .Custom11:
            return "custom11"
        }
    }
}

public enum VertexBufferIndex: Int {
    case Vertices = 0
    case Generics = 1
    case VertexUniforms = 2
    case InstanceMatrixUniforms = 3
    case MaterialUniforms = 4
    case Custom0 = 5
    case Custom1 = 6
    case Custom2 = 7
    case Custom3 = 8
    case Custom4 = 9
    case Custom5 = 10
    case Custom6 = 11
    case Custom7 = 12
    case Custom8 = 13
    case Custom9 = 14
    case Custom10 = 15
}

public enum VertexTextureIndex: Int {
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
}

public enum FragmentConstantIndex: Int {
    case Custom0 = 0
}

public enum FragmentBufferIndex: Int {
    case MaterialUniforms = 0
    case Lighting = 1
    case Custom0 = 2
    case Custom1 = 3
    case Custom2 = 4
    case Custom3 = 5
    case Custom4 = 6
    case Custom5 = 7
    case Custom6 = 8
    case Custom7 = 9
    case Custom8 = 10
    case Custom9 = 11
    case Custom10 = 12
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
}

public enum PBRTexture: Int {
    case baseColor = 0
    case metallic = 1
    case roughness = 2
    case normal = 3
    case emissive = 4
    case specular = 5
    case sheen = 6
    case specularHighlight = 7
    case anisotropy = 8
    case anisotropyAngle = 9
    case bump = 10
    case displacement = 11
    case alpha = 12
    case ambient = 13
    case ambientOcculsion = 14
    case reflection = 15
    case irradiance = 16
    
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
        case .specularHighlight:
            return "SPECULAR_HIGHLIGHT_MAP"
        case .anisotropy:
            return "ANISOTROPY_MAP"
        case .anisotropyAngle:
            return "ANISOTROPY_ANGLE_MAP"
        case .bump:
            return "BUMP_MAP"
        case .displacement:
            return "DISPLACEMENT_MAP"
        case .alpha:
            return "ALPHA_MAP"
        case .ambient:
            return "AMBIENT_MAP"
        case .ambientOcculsion:
            return "AMBIENT_OCCULSION_MAP"
        case .reflection:
            return "REFLECTION_MAP"
        case .irradiance:
            return "IRRADIANCE_MAP"
        }
    }
    
    public var textureType: String {
        switch self {
        case .irradiance:
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
        case .specularHighlight:
            return "specularHighlightMap"
        case .anisotropy:
            return "anisotropyMap"
        case .anisotropyAngle:
            return "anisotropyAngleMap"
        case .bump:
            return "bumpMap"
        case .displacement:
            return "displacementMap"
        case .alpha:
            return "alphaMap"
        case .ambient:
            return "ambientMap"
        case .ambientOcculsion:
            return "ambientOcclusionMap"
        case .reflection:
            return "reflectionMap"
        case .irradiance:
            return "irradianceMap"
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
        case .specularHighlight:
            return "PBRTextureSpecularHighlight"
        case .anisotropy:
            return "PBRTextureAnisotropy"
        case .anisotropyAngle:
            return "PBRTextureAnisotropyAngle"
        case .bump:
            return "PBRTextureBump"
        case .displacement:
            return "PBRTextureDisplacement"
        case .alpha:
            return "PBRTextureAlpha"
        case .ambient:
            return "PBRTextureAmbient"
        case .ambientOcculsion:
            return "PBRTextureAmbientOcculsion"
        case .reflection:
            return "PBRTextureReflection"
        case .irradiance:
            return "PBRTextureIrradiance"
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
}

public enum ComputeBufferIndex: Int {
    case Uniforms = 0
    case Custom0 = 1
    case Custom1 = 2
    case Custom2 = 3
    case Custom3 = 4
    case Custom4 = 5
    case Custom5 = 6
    case Custom6 = 7
    case Custom7 = 8
    case Custom8 = 9
    case Custom9 = 10
    case Custom10 = 11
}

public enum ComputeTextureIndex: Int {
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
}
