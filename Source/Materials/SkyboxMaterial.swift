//
//  SkyboxMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal
import simd

open class SkyboxMaterial: BasicTextureMaterial {
    public override init() {
        super.init()        
        self.depthWriteEnabled = false
    }
    
    public override init(texture: MTLTexture, sampler: MTLSamplerState? = nil) {
        super.init()
        if texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
        self.depthWriteEnabled = false
    }

    open override func compileSource() -> String? {
        return SkyboxPipelineSource.setup(label: label, parameters: parameters)
    }

    open override func setupPipeline() {
        guard let _ = self.context else { return }
        guard let source = compileSource() else { return }
        guard let library = makeLibrary(source) else { return }
        guard let pipeline = createPipeline(library, vertex: label.camelCase + "Vertex") else { return }
        self.pipeline = pipeline
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
