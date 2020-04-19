//
//  BasicTextureMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal
import simd

open class BasicTextureMaterial: Material {
    public var texture: MTLTexture?
    public var sampler: MTLSamplerState?

    public override init() {
        super.init()
    }

    public init(texture: MTLTexture, sampler: MTLSamplerState? = nil) {
        if texture.textureType != .type2D || texture.textureType != .type2DMultisample {
            fatalError("Basic texture material expects a 2D texture")
        }
        self.texture = texture
        self.sampler = sampler
        super.init()
    }

    override func setup() {
        setupPipeline()
        setupSampler()
    }
    
    func setupSampler()
    {
        guard sampler == nil else { return }
        let desc = MTLSamplerDescriptor()
        desc.label = label.titleCase
        desc.minFilter = .linear
        desc.magFilter = .linear
        sampler = context?.device.makeSamplerState(descriptor: desc)
    }

    func setupPipeline() {
        BasicTexturePipeline.setup(context: context, label: label)
        if let pipeline = BasicTexturePipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        if let texture = self.texture {
            renderEncoder.setFragmentTexture(texture, index: FragmentTextureIndex.Custom0.rawValue)
        }
        if let sampler = self.sampler {
            renderEncoder.setFragmentSamplerState(sampler, index: FragmentSamplerIndex.Custom0.rawValue)
        }
        super.bind(renderEncoder)
    }
}

class BasicTexturePipeline {
    static let shared = BasicTexturePipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?, label: String) {
        guard BasicTexturePipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }

        do {
            if let source = try makePipelineSource(pipelinesPath, label) {
                let library = try context.device.makeLibrary(source: source, options: .none)
                let pipeline = try makeAlphaRenderPipeline(
                    library: library,
                    vertex: "satinVertex",
                    fragment: label.camelCase + "Fragment",
                    label: label.titleCase,
                    context: context)

                BasicTexturePipeline.sharedPipeline = pipeline
            }
        }
        catch {
            print(error)
            return
        }
    }

    init() {
        pipeline = BasicTexturePipeline.sharedPipeline
    }
}
