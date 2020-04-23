//
//  BasicColorMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class NormalColorMaterial: Material {
    var absolute = BoolParameter("absolute")

    lazy var parameters: ParameterGroup = {
        let params = ParameterGroup(label+"Uniforms")
        params.append(absolute)
        return params
    }()

    var uniforms: UniformBuffer?

    public init(_ absolute: Bool = false) {
        super.init()
        self.absolute.value = absolute
    }

    open override func setup() {
        super.setup()
        setupPipeline()
        setupUniforms()
    }

    open override func update() {
        super.update()
        uniforms?.update()
    }

    func setupPipeline() {
        NormalColorPipeline.setup(context: context, label: label, parameters: parameters)
        if let pipeline = NormalColorPipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }

    func setupUniforms() {
        guard let context = self.context else { return }
        uniforms = UniformBuffer(context: context, parameters: parameters)
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
        if let uniforms = self.uniforms {
            renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        }        
    }
}

class NormalColorPipeline {
    static let shared = NormalColorPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?, label: String, parameters: ParameterGroup) {
        guard NormalColorPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }

        do {
            if let source = try makePipelineSource(pipelinesPath, label, parameters) {
                let library = try context.device.makeLibrary(source: source, options: .none)

                let pipeline = try makeRenderPipeline(
                    library: library,
                    vertex: "satinVertex",
                    fragment: label.camelCase + "Fragment",
                    label: label.titleCase,
                    context: context)

                NormalColorPipeline.sharedPipeline = pipeline
            }
        }
        catch {
            print(error)
            return
        }
    }

    init() {
        pipeline = NormalColorPipeline.sharedPipeline
    }
}
