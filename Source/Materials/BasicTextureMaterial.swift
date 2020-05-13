//
//  BasicTextureMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal
import simd

open class BasicTextureMaterial: BasicColorMaterial {
    public var texture: MTLTexture?
    public var sampler: MTLSamplerState?

    public init() {
        super.init()
    }

    public init(texture: MTLTexture, sampler: MTLSamplerState? = nil) {
        super.init()
        if texture.textureType != .type2D || texture.textureType != .type2DMultisample {
            fatalError("BasicTextureMaterial expects a 2D texture")
        }
        self.texture = texture
        self.sampler = sampler
    }

    open override func setup() {
        super.setup()
        setupSampler()
    }

    func setupSampler() {
        guard sampler == nil else { return }
        let desc = MTLSamplerDescriptor()
        desc.label = label.titleCase
        desc.minFilter = .linear
        desc.magFilter = .linear
        sampler = context?.device.makeSamplerState(descriptor: desc)
    }

    open override func compileSource() -> String? {
        return BasicTexturePipelineSource.setup(label: label, parameters: parameters)
    }

    open func bindTexture(_ renderEncoder: MTLRenderCommandEncoder) {
        if let texture = self.texture {
            renderEncoder.setFragmentTexture(texture, index: FragmentTextureIndex.Custom0.rawValue)
        }
    }

    open func bindSampler(_ renderEncoder: MTLRenderCommandEncoder) {
        if let sampler = self.sampler {
            renderEncoder.setFragmentSamplerState(sampler, index: FragmentSamplerIndex.Custom0.rawValue)
        }
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        bindTexture(renderEncoder)
        bindSampler(renderEncoder)
        super.bind(renderEncoder)
    }
}

class BasicTexturePipelineSource {
    static let shared = BasicTexturePipelineSource()
    private static var sharedSource: String?

    class func setup(label: String, parameters: ParameterGroup) -> String? {
        guard BasicTexturePipelineSource.sharedSource == nil else { return sharedSource }
        do {
            if let source = try compilePipelineSource(label, parameters) {
                BasicTexturePipelineSource.sharedSource = source
            }
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
