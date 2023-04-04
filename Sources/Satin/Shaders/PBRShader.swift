//
//  PBRShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal


open class PBRShader: SourceShader {
    open var maps: [PBRTextureIndex: MTLTexture?] = [:] {
        didSet {
            if oldValue.keys != maps.keys {
                sourceNeedsUpdate = true
            }
        }
    }

    open var samplers: [PBRTextureIndex: MTLSamplerDescriptor?] = [:] {
        didSet {
            if oldValue.keys != samplers.keys {
                sourceNeedsUpdate = true
            }
        }
    }

    override open var defines: [String: NSObject] {
        var results = super.defines
        if !maps.isEmpty { results["HAS_MAPS"] = NSString(string: "true") }
        for map in maps { results[map.key.shaderDefine] = NSString(string: "true") }
        return results
    }

    override open var constants: [String] {
        var results = super.constants
        for (index, sampler) in samplers where sampler != nil {
            results.append(sampler!.shaderInjection(index: index))
        }
        if !samplers.isEmpty { results.append("") }
        results.append("// inject pbr constants")
        return results
    }

    override open func modifyShaderSource(source: inout String) {
        super.modifyShaderSource(source: &source)
        injectPBRConstants(source: &source)
    }
}
