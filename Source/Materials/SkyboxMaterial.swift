//
//  SkyboxMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal
import simd

open class SkyboxMaterial: BasicTextureMaterial {
    public override init(texture: MTLTexture, sampler: MTLSamplerState? = nil) {
        super.init()
        if texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
    }

    
    open override func compileSource() -> String? {
        return SkyboxPipelineSource.setup(label: label, parameters: parameters)
    }
}

class SkyboxPipelineSource {
    static let shared = SkyboxPipelineSource()
    private static var sharedSource: String?

    class func setup(label: String, parameters: ParameterGroup) -> String? {
        guard SkyboxPipelineSource.sharedSource == nil else { return sharedSource }
        do {
            SkyboxPipelineSource.sharedSource = try compilePipelineSource(label, parameters)
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
