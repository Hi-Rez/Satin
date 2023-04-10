//
//  SkyboxShader.swift
//  
//
//  Created by Reza Ali on 4/10/23.
//

import Foundation
import Metal

open class SkyboxShader: SourceShader {
    open var tonemapping: Tonemapping = .aces {
        didSet {
            if oldValue != tonemapping {
                sourceNeedsUpdate = true
            }
        }
    }

    override open var defines: [String: NSObject] {
        var results = super.defines
        results[tonemapping.shaderDefine] = NSString(string: "true")
        return results
    }
}

