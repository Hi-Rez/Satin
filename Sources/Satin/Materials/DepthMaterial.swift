//
//  DepthMaterial.swift
//  Satin
//
//  Created by Reza Ali on 6/24/20.
//

import Metal

open class DepthMaterial: Material {
    public init(_ color: Bool = true, _ invert: Bool = false) {
        super.init()
        createShader()
        set("Color", color)
        set("Invert", invert)
        set("Near", -1)
        set("Far", -1)
    }
    
    public required init() {
        super.init()
        createShader()
        set("Color", true)
        set("Invert", false)
        set("Near", -1)
        set("Far", -1)
    }
}
