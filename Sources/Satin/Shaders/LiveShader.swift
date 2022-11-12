//
//  LiveShader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Foundation
import Metal

open class LiveShader: SourceShader {
    let compiler = MetalFileCompiler()

    public required init() {
        fatalError("init() has not been implemented")
    }

    public required init(_ label: String, _ pipelineURL: URL, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil) {
        super.init(label, pipelineURL, vertexFunctionName, fragmentFunctionName)
        setupCompiler()
    }

    public required init(label: String, source: String, vertexFunctionName: String? = nil, fragmentFunctionName: String? = nil) {
        fatalError("init(_:_:_:_:) has not been implemented")
    }

    func setupCompiler() {
        compiler.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.sourceNeedsUpdate = true
        }
    }

    override open func setupShaderSource() -> String? {
        guard let pipelineURL = pipelineURL else { return nil }
        do {
            return try compiler.parse(pipelineURL)
        }
        catch {
            self.error = error
            print("\(label) Shader: \(error.localizedDescription)")
        }

        return nil
    }
}
