//
//  SkyboxMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal

open class SkyboxMaterial: BasicTextureMaterial {
    public required init() {
        super.init()
        self.depthWriteEnabled = false
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    override public init(texture: MTLTexture?, sampler: MTLSamplerState? = nil) {
        super.init()
        if let texture = texture, texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
        self.depthWriteEnabled = false
    }

    override public init(texture: MTLTexture, sampler: MTLSamplerState? = nil) {
        super.init()
        if texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
        self.depthWriteEnabled = false
    }
}
