//
//  SkyboxMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal

open class SkyboxMaterial: BasicTextureMaterial {
    override public var texture: MTLTexture? {
        willSet {
            if let newTexture = newValue, newTexture.textureType != .typeCube {
                fatalError("SkyboxMaterial expects a Cube Texture")
            }
        }
    }
    
    public init(tonemapped: Bool = false, gammaCorrected: Bool = false) {
        super.init()
        depthWriteEnabled = false
        initalizeParameters(tonemapped: tonemapped, gammaCorrected: gammaCorrected)
    }
    
    public init(texture: MTLTexture, sampler: MTLSamplerState? = nil, tonemapped: Bool = false, gammaCorrected: Bool = false) {
        super.init()
        if texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
        depthWriteEnabled = false
        initalizeParameters(tonemapped: tonemapped, gammaCorrected: gammaCorrected)
    }
    
    func initalizeParameters(tonemapped: Bool = false, gammaCorrected: Bool = false) {
        set("Tone Mapped", tonemapped)
        set("Gamma Corrected", gammaCorrected)
    }
    
    public required init() {
        super.init()
        depthWriteEnabled = false
        initalizeParameters()
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        depthWriteEnabled = false
    }

    override public init(texture: MTLTexture?, sampler: MTLSamplerState? = nil) {
        super.init(texture: texture, sampler: sampler)
        if let texture = texture, texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
        depthWriteEnabled = false
        initalizeParameters()
    }
}
