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
        set("Color", color)
        set("Invert", invert)
        set("Near", -1.0)
        set("Far", -1.0)
    }
    
    public required init() {
        super.init()
        set("Color", true)
        set("Invert", false)
        set("Near", -1.0)
        set("Far", -1.0)
    }
}
