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
    public var source: String?
    public var pipelineURL: URL

    public init(pipelineURL: URL, instance: String = "") {
        self.pipelineURL = pipelineURL
        self.instance = instance
        super.init()
        self.source = self.compileSource()
    }
    
    public init(pipelinesURL: URL, instance: String = "") {
        self.pipelineURL = pipelinesURL
        self.instance = instance
        super.init()
        self.pipelineURL = self.pipelineURL.appendingPathComponent(label).appendingPathComponent("Shaders.metal")
        self.source = self.compileSource()
    }

    open override func setup() {
        super.setup()
        setupCompiler()
    }

    open func setupCompiler() {
        compiler.onUpdate = { [unowned self] in
            self.source = nil
            self.setupPipeline()
        }
    }

    open override func compileSource() -> String? {
        if let source = self.source {
            return source
        }
        else {
            guard let satinURL = getPipelinesSatinUrl() else { return nil }
            let includesURL = satinURL.appendingPathComponent("Includes.metal")
            do {
                var source = try compiler.parse(includesURL)
                let shaderSource = try compiler.parse(pipelineURL)
                parseUniforms(shaderSource)
                source += shaderSource
                self.source = source
                return source
            }
            catch {
                print(error)
            }
            return nil
        }
    }

    open func parseUniforms(_ source: String) {
        if let params = parseParameters(source: source, key: label + "Uniforms") {
            params.label = label.titleCase + (instance.isEmpty ? "" : " \(instance)")
            parameters.setFrom(params)
            setupUniforms()
        }
    }
}
