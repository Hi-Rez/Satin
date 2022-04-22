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

    func setupCompiler() {
        compiler.onUpdate = { [unowned self] in
            setup()
        }
    }

    override func setupShaderSource() -> String? {
        do {
            return try compiler.parse(pipelineURL)
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
        return nil
    }
}
