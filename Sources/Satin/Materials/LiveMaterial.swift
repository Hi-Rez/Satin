//
//  LiveMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/23/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Metal

open class LiveMaterial: Material {
    public var source: String? {
        shader?.source
    }
    
    public init(pipelineURL: URL) {
        super.init(pipelineURL)
    }

    public init(pipelinesURL: URL) {
        super.init(pipelinesURL)
    }
    
    override func generateShader() -> Shader {
        if pipelineURL.pathExtension != "metal" {
            pipelineURL = pipelineURL.appendingPathComponent(label).appendingPathComponent("Shaders.metal")
        }
        return LiveShader(label, pipelineURL)
    }
}
