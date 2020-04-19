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
        let params = ParameterGroup("NormalColorUniforms")
        params.append(absolute)
        return params
    }()

    var uniforms: UniformBuffer?

    public init(_ absolute: Bool = false) {
        super.init()
        self.absolute.value = absolute
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
        NormalColorPipeline.setup(context: context, parameters: parameters)
        if let pipeline = NormalColorPipeline.shared.pipeline {
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

class NormalColorPipeline {
    static let shared = NormalColorPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?, parameters: ParameterGroup) {
        guard NormalColorPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }

        let pipelinesURL = URL(fileURLWithPath: pipelinesPath)
        let materialsURL = pipelinesURL.appendingPathComponent("Materials")
        let commonURL = materialsURL.appendingPathComponent("Common")
        
        let includesURL = commonURL.appendingPathComponent("Includes.metal")
        let vertexURL = commonURL.appendingPathComponent("Vertex.metal")
        
        let materialURL = materialsURL.appendingPathComponent("NormalColor")
        let fragmentURL = materialURL.appendingPathComponent("Fragment.metal")

        let metalFileCompiler = MetalFileCompiler()
        do {
            var source = try metalFileCompiler.parse(includesURL)
            source += parameters.structString
            source += try metalFileCompiler.parse(vertexURL)
            source += try metalFileCompiler.parse(fragmentURL)

            let library = try context.device.makeLibrary(source: source, options: .none)

            let pipeline = try makeRenderPipeline(
                library: library,
                vertex: "vert",
                fragment: "normalColorFragment",
                label: "Normal Color",
                context: context)

            NormalColorPipeline.sharedPipeline = pipeline
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
