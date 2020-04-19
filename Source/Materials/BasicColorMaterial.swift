//
//  BasicColorMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class BasicColorMaterial: Material {
    var color = Float4Parameter("color")

    lazy var parameters: ParameterGroup = {
        let params = ParameterGroup(label+"Uniforms")
        params.append(color)
        return params
    }()

    var uniforms: UniformBuffer?

    public init(_ color: simd_float4) {
        super.init()
        self.color.value = color
    }

    override func setup() {
        setupPipeline()
        setupUniforms()
    }

    override func update() {
        uniforms?.update()
        super.update()
    }

    func setupPipeline() {
        BasicColorPipeline.setup(context: context, label: label, parameters: parameters)
        if let pipeline = BasicColorPipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }

    func setupUniforms() {
        guard let context = self.context else { return }
        uniforms = UniformBuffer(context: context, parameters: parameters)
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        if let uniforms = self.uniforms {
            renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        }
        super.bind(renderEncoder)
    }
}

class BasicColorPipeline {
    static let shared = BasicColorPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?, label: String, parameters: ParameterGroup) {
        guard BasicColorPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }
        do {
            if let source = try makePipelineSource(pipelinesPath, label, parameters) {
                let library = try context.device.makeLibrary(source: source, options: .none)
                let pipeline = try makeAlphaRenderPipeline(
                    library: library,
                    vertex: "satinVertex",
                    fragment: label.camelCase + "Fragment",
                    label: label.titleCase,
                    context: context)
                
                BasicColorPipeline.sharedPipeline = pipeline
            }
        }
        catch {
            print(error)
            return
        }
    }

    init() {
        pipeline = BasicColorPipeline.sharedPipeline
    }
}
