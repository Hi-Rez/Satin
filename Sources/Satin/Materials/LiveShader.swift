//
//  LiveShader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Foundation

class LiveShader: Shader {
    let compiler = MetalFileCompiler()

    override public init(_ label: String, _ pipelineURL: URL) {
        super.init(label, pipelineURL)
        setupCompiler()
    }

    func setupCompiler() {
        compiler.onUpdate = { [unowned self] in
            updateSource()
            updateLibrary()
            updatePipeline()
        }
    }

    override func setupShaderSource() -> String? {
        do {
            return try compiler.parse(pipelineURL)
        }
        catch {
            print(error.localizedDescription)
        }
        return nil
    }
}
