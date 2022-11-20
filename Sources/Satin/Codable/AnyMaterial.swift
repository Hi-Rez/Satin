//
//  AnyMaterial.swift
//  
//
//  Created by Reza Ali on 11/18/22.
//

import Foundation

public enum MaterialType: String, Codable {
    case base, basiccolor, basicdiffuse, basicpoint, basictexture, depth, live, matcap, normal, skybox, standard, uvcolor

    var metaType: Material.Type {
        switch self {
        case .base:
            return Material.self
        case .basiccolor:
            return BasicColorMaterial.self
        case .basicdiffuse:
            return BasicDiffuseMaterial.self
        case .basicpoint:
            return BasicPointMaterial.self
        case .basictexture:
            return BasicTextureMaterial.self
        case .depth:
            return DepthMaterial.self
        case .live:
            return LiveMaterial.self
        case .matcap:
            return MatCapMaterial.self
        case .normal:
            return NormalColorMaterial.self
        case .skybox:
            return SkyboxMaterial.self
        case .standard:
            return StandardMaterial.self
        case .uvcolor:
            return UvColorMaterial.self
        }
    }
}

open class AnyMaterial: Codable {
    public var type: MaterialType
    public var material: Material

    public init(_ material: Material) {
        self.material = material
        
        if material is BasicColorMaterial {
            self.type = .basiccolor
        }
        else if material is BasicDiffuseMaterial {
            self.type = .basicdiffuse
        }
        else if material is BasicPointMaterial {
            self.type = .basicpoint
        }
        else if material is BasicTextureMaterial {
            self.type = .basictexture
        }
        else if material is DepthMaterial {
            self.type = .depth
        }
        else if material is LiveMaterial {
            self.type = .live
        }
        else if material is MatCapMaterial {
            self.type = .matcap
        }
        else if material is NormalColorMaterial {
            self.type = .normal
        }
        else if material is SkyboxMaterial {
            self.type = .skybox
        }
        else if material is StandardMaterial {
            self.type = .standard
        }
        else if material is UvColorMaterial {
            self.type = .uvcolor
        }
        else {
            self.type = .base
        }
    }

    private enum CodingKeys: CodingKey {
        case type, material
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MaterialType.self, forKey: .type)
        material = try type.metaType.init(from: container.superDecoder(forKey: .material))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try material.encode(to: container.superEncoder(forKey: .material))
    }
}
