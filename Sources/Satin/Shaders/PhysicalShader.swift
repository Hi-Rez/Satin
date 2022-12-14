//
//  PhysicalShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class PhysicalShader: StandardShader {
    open override var defines: [String: String] {
        var results = super.defines
        results["HAS_CLEAR_COAT"] = "true"
        return results
    }

    open override func modifyShaderSource(source: inout String) {
        super.modifyShaderSource(source: &source)
        injectTexturesArgs(source: &source, maps: maps)
    }
}

