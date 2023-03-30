//
//  PhysicalShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class PhysicalShader: PBRShader {
    override open var defines: [String: String] {
        var results = super.defines
        results["HAS_CLEARCOAT"] = "true"
        results["HAS_SUBSURFACE"] = "true"
        results["HAS_SPECULAR_TINT"] = "true"
        results["HAS_SHEEN"] = "true"
        results["HAS_TRANSMISSION"] = "true"
        results["HAS_ANISOTROPIC"] = "true"
        return results
    }
}
