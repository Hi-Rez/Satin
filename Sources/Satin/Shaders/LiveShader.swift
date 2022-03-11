//
//  LiveShader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Foundation

class LiveShader: SourceShader {
    let compiler = MetalFileCompiler()

    public required init(_ label: String, _ pipelineURL: URL) {
        super.init(label, pipelineURL)
        setupCompiler()
    }

    public required init() {
        fatalError("init() has not been implemented")
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
