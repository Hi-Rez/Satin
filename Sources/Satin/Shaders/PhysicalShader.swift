//
//  PhysicalShader.swift
//  Satin
//
//  Created by Reza Ali on 12/9/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

open class PhysicalShader: PBRShader {
    override open var defines: [String: NSObject] {
        var results = super.defines
        results["HAS_CLEARCOAT"] = NSString(string: "true")
        results["HAS_SUBSURFACE"] = NSString(string: "true")
        results["HAS_SPECULAR_TINT"] = NSString(string: "true")
        results["HAS_SHEEN"] = NSString(string: "true")
        results["HAS_TRANSMISSION"] = NSString(string: "true")
        results["HAS_ANISOTROPIC"] = NSString(string: "true")
        return results
    }
}
