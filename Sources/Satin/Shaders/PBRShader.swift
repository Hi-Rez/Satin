//
//  PBRShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class PBRShader: SourceShader {
    open var maps = Set<PBRTextureIndex>() {
        didSet {
            if oldValue != maps {
                sourceNeedsUpdate = true
            }
        }
    }

    override open var defines: [String: NSObject] {
        var results = super.defines
        if !maps.isEmpty {
            results["HAS_MAPS"] = NSString(string: "true")
        }
        for map in maps { results[map.shaderDefine] = NSString(string: "true") }
        return results
    }

    override open func modifyShaderSource(source: inout String) {
        super.modifyShaderSource(source: &source)
        injectPBRTexturesArgs(source: &source, maps: maps)
    }
}
