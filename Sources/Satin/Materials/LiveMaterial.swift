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
        if let live = shader as? LiveShader {
            return live.source
        }
        return nil
    }

    public init(pipelineURL: URL, vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor) {
        super.init()
        self.vertexDescriptor = vertexDescriptor
        _init(pipelineURL: pipelineURL)
    }

    public init(pipelinesURL: URL, vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor) {
        super.init()
        self.vertexDescriptor = vertexDescriptor
        _init(pipelineURL: pipelinesURL.appendingPathComponent(label).appendingPathComponent("Shaders.metal"))
    }
    
    func _init(pipelineURL: URL) {
        self.shader = LiveShader(label, pipelineURL)
    }
    
    public required init() {
        super.init()
    }
}
