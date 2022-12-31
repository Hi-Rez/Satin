//
//  SourceMaterial.swift
//  Satin
//
//  Created by Reza Ali on 12/31/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class SourceMaterial: Material {
    public enum CodingKeys: String, CodingKey {
        case pipelineURL
    }
    
    public var pipelineURL: URL
    
    public var source: String? {
        if let shader = shader as? SourceShader {
            return shader.source
        }
        return nil
    }

    public init(pipelineURL: URL) {
        self.pipelineURL = pipelineURL
        super.init()
    }

    public init(pipelinesURL: URL) {
        pipelineURL = pipelinesURL
        super.init()
        if pipelinesURL.pathExtension != "metal" {
            pipelineURL = pipelinesURL
                .appendingPathComponent(label)
                .appendingPathComponent("Shaders.metal")
        }
    }
    
    override open func createShader() -> Shader {
        return SourceShader(label, pipelineURL)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pipelineURL = try values.decode(URL.self, forKey: .pipelineURL)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pipelineURL, forKey: .pipelineURL)
    }
    
    public required init() {
        fatalError("Please specify a pipeline url to use SourceMaterial")
    }
}
