//
//  TessellatedMaterial.swift
//  Tesselation
//
//  Created by Reza Ali on 4/1/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Satin

class TessellatedMaterial: SourceMaterial {
    unowned var geometry: TessellatedGeometry

    public init(pipelinesURL: URL, geometry: TessellatedGeometry) {
        self.geometry = geometry
        super.init(pipelinesURL: pipelinesURL)
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override func createShader() -> Shader {
        return TessellatedShader(label, pipelineURL, geometry)
    }
}
