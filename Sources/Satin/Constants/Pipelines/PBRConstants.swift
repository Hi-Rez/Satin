//
//  PBRConstants.swift
//
//
//  Created by Reza Ali on 3/17/23.
//

import Foundation

public enum PBRTextureIndex: Int {
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
        return description.titleCase.uppercased().replacingOccurrences(of: " ", with: "_") + "_MAP"
    }

    public var textureType: String {
        switch self {
            case .irradiance, .reflection:
                return "texturecube"
            default:
                return "texture2d"
        }
    }

    public var description: String {
        return String(describing: self)
    }

    public var samplerName: String {
        return description + "Sampler"
    }

    public var textureName: String {
        return description + "Map"
    }

    public var texcoordName: String {
        switch self {
            case .clearcoatGloss:
                return PBRTextureIndex.clearcoatRoughness.texcoordName
        default:
            return description + "TexcoordTransform"
        }
    }

    public var textureIndex: String {
        return "PBRTexture" + Substring(description.prefix(1).uppercased()) + Substring(description.dropFirst())
    }

    public static var allTexcoordCases: [PBRTextureIndex] {
        return [
            .baseColor,
            .subsurface,
            .metallic,
            .roughness,
            .normal,
            .emissive,
            .specular,
            .specularTint,
            .sheen,
            .sheenTint,
            .clearcoat,
            .clearcoatRoughness,
            .anisotropic,
            .anisotropicAngle,
            .bump,
            .displacement,
            .alpha,
            .ior,
            .transmission,
            .ambientOcclusion
        ]
    }
}
