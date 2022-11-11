//
//  StandardShader.swift
//  PBRTemplate
//
//  Created by Reza Ali on 11/5/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class StandardShader: SourceShader {
    var maps = Set<PBRTexture>() {
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
