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
    public var live: Bool = false {
        didSet {
            if let shader = shader as? SourceShader {
                shader.live = live
            }
        }
    }

    public var source: String? {
        if let shader = shader as? SourceShader {
            return shader.source
        }
        return nil
    }

    public init(pipelineURL: URL, live: Bool = false) {
        self.pipelineURL = pipelineURL
        self.live = live
        super.init()
    }

    public init(pipelinesURL: URL, live: Bool = false) {
        pipelineURL = pipelinesURL
        self.live = live
        super.init()
        if pipelinesURL.pathExtension != "metal" {
            pipelineURL = pipelinesURL
                .appendingPathComponent(label)
                .appendingPathComponent("Shaders.metal")
        }
    }

    override open func createShader() -> Shader {
        let shader = SourceShader(label, pipelineURL)
        shader.live = live
        return shader
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

    override public func clone() -> Material {
        let clone = SourceMaterial(pipelineURL: pipelineURL, live: live)
        clone.isClone = true
        cloneProperties(clone: clone)
        return clone
    }
}
