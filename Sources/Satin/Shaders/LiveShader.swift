//
//  LiveShader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Foundation
import Metal

open class LiveShader: SourceShader {
    public required init() {
        super.init()
        self.live = true
    }

    public required init(_ label: String, _ pipelineURL: URL, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil) {
        super.init(label, pipelineURL, vertexFunctionName, fragmentFunctionName)
        self.live = true
    }

    public required init(label: String, source: String, vertexFunctionName: String? = nil, fragmentFunctionName: String? = nil) {
        super.init(label: label, source: source, vertexFunctionName: vertexFunctionName, fragmentFunctionName: fragmentFunctionName)
        self.live = true
    }
}
