//
//  LiveMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/23/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Satin

open class LiveMaterial: Material {
    public var params: ParameterGroup?
    var uniforms: UniformBuffer?
    var metalFileCompiler = MetalFileCompiler()
    var instance: String = ""
    var pipelinePath: String = ""

    public init(pipelinePath: String = "", instance: String = "") {
        super.init()
        self.pipelinePath = pipelinePath
        self.instance = instance
    }

    open override func setup() {
        super.setup()
        setupCompiler()
        setupPipeline()
    }

    open override func update() {
        uniforms?.update()
        super.update()
    }

    func setupCompiler() {
        metalFileCompiler.onUpdate = { [unowned self] in
            self.setupPipeline()
        }
    }

    func parseUniforms(_ source: String) {
        if let params = parseParameters(source: source, key: label.titleCase + "Uniforms") {
            params.label = label.lowercased() + " uniforms" + (instance.isEmpty ? "" : " \(instance)")
            if self.params == nil {
                self.params = params
            }
            else if let existingParams = self.params {
                existingParams.setFrom(params)
            }
            setupUniforms()
        }
    }

    func setupPipeline() {
        guard let context = self.context, !pipelinePath.isEmpty else { return }
        guard let satinIncludes = getSatinPipelinesPath("Includes.metal") else { return }
        do {
            var source = try metalFileCompiler.parse(URL(fileURLWithPath: satinIncludes))
            source += try metalFileCompiler.parse(URL(fileURLWithPath: pipelinePath))
            parseUniforms(source)

            let library = try context.device.makeLibrary(source: source, options: .none)
            pipeline = try makeAlphaRenderPipeline(
                library: library,
                vertex: label.camelCase + "Vertex",
                fragment: label.camelCase + "Fragment",
                label: label.titleCase,
                context: context)

            delegate?.materialUpdated(material: self)
        }
        catch {
            print(error)
        }
    }

    func setupUniforms() {
        guard let context = self.context else { return }
        if let params = self.params, params.size > 0 {
            uniforms = UniformBuffer(context: context, parameters: params)
        }
        else {
            uniforms = nil
        }
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
        if let uniforms = self.uniforms {
            renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        }
    }
}
