//
//  PBRShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class PBRShader: SourceShader {
    open var maps = Set<PBRTexture>() {
        didSet {
            if oldValue != maps {
                sourceNeedsUpdate = true
            }
        }
    }

    open override var defines: [String: String] {
        var results = super.defines
        if !maps.isEmpty {
            results["HAS_MAPS"] = "true"
        }
        for map in maps { results[map.shaderDefine] = "true" }
        return results
    }

    open override func modifyShaderSource(source: inout String) {
        super.modifyShaderSource(source: &source)
        injectTexturesArgs(source: &source, maps: maps)
    }
}
