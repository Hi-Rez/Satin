//
//  LiveMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/23/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Metal

open class LiveMaterial: Material {
    public var compiler = MetalFileCompiler()
    public var instance: String = ""
    public var pipelineURL: URL

    public init(pipelineURL: URL, instance: String = "") {
        self.pipelineURL = pipelineURL
        self.instance = instance
        super.init()
    }

    open override func setup() {
        super.setup()
        setupCompiler()
    }

    open func setupCompiler() {
        compiler.onUpdate = { [unowned self] in
            self.setupPipeline()
        }
    }

    open override func setupPipeline() {
        guard let source = compileSource() else { return }
        guard let library = makeLibrary(source) else { return }
        guard let pipeline = createPipeline(library, vertex: label.camelCase + "Vertex", fragment: label.camelCase + "Fragment") else { return }
        self.pipeline = pipeline
    }

    open override func compileSource() -> String? {
        guard let satinURL = getPipelinesSatinUrl() else { return nil }
        let includesURL = satinURL.appendingPathComponent("Includes.metal")
        do {
            var source = try compiler.parse(includesURL)
            let shaderSource = try compiler.parse(pipelineURL)
            parseUniforms(shaderSource)
            source += shaderSource
            return source
        }
        catch {
            print(error)
        }
        return nil
    }

    open func parseUniforms(_ source: String) {
        if let params = parseParameters(source: source, key: label + "Uniforms") {
            params.label = label.titleCase + (instance.isEmpty ? "" : " \(instance)")
            parameters.setFrom(params)            
            setupUniforms()
        }
    }
}
