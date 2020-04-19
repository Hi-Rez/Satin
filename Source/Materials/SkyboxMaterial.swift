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
        if texture.textureType != .typeCube {
            fatalError("Skybox material expects a Cube texture")
        }
        super.init()
        self.texture = texture
        self.sampler = sampler
    }

    override func setupPipeline() {
        SkyboxPipeline.setup(context: context, label: label)
        if let pipeline = SkyboxPipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }
}

class SkyboxPipeline {
    static let shared = SkyboxPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?, label: String) {
        guard SkyboxPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }

        do {
            if let source = try makePipelineSource(pipelinesPath, label) {
                let library = try context.device.makeLibrary(source: source, options: .none)
                let pipeline = try makeRenderPipeline(
                    library: library,
                    vertex: label.camelCase + "Vertex",
                    fragment: label.camelCase + "Fragment",
                    label: label.titleCase,
                    context: context)

                SkyboxPipeline.sharedPipeline = pipeline
            }
        }
        catch {
            print(error)
            return
        }
    }

    init() {
        pipeline = SkyboxPipeline.sharedPipeline
    }
}
