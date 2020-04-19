//
//  SkyboxMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal
import simd

open class SkyboxMaterial: Material {
    public var texture: MTLTexture?

    public override init() {
        super.init()
    }

    public init(texture: MTLTexture) {
        if texture.textureType != .typeCube {
            fatalError("Skybox material expects a Cube texture")
        }
        self.texture = texture
        super.init()
    }

    override func setup() {
        setupPipeline()
    }

    func setupPipeline() {
        SkyboxPipeline.setup(context: context)
        if let pipeline = SkyboxPipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        if let texture = self.texture {
            renderEncoder.setFragmentTexture(texture, index: FragmentTextureIndex.Custom0.rawValue)
        }
        super.bind(renderEncoder)
    }
}

class SkyboxPipeline {
    static let shared = SkyboxPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?) {
        guard SkyboxPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }

        do {
            if let source = try makePipelineSource(pipelinesPath, "Skybox") {
                let library = try context.device.makeLibrary(source: source, options: .none)
                let pipeline = try makeRenderPipeline(
                    library: library,
                    vertex: "skyboxVertex",
                    fragment: "skyboxFragment",
                    label: "Skybox",
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
