//
//  LiveMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/23/20.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Metal

open class LiveMaterial: SourceMaterial {
    public override init(pipelineURL: URL) {
        super.init(pipelineURL: pipelineURL)
    }

    public override init(pipelinesURL: URL) {
        super.init(pipelinesURL: pipelinesURL)
    }
    
    open override func createShader() -> Shader {
        return LiveShader(label, pipelineURL)
    }
    
    public required init() {
        fatalError("Please specify a pipeline url to use LiveMaterial")
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
