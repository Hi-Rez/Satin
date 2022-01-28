//
//  BasicDiffuseMaterial.swift
//  Satin
//
//  Created by Reza Ali on 7/26/20.
//

import Metal

open class BasicDiffuseMaterial: BasicColorMaterial {
    public init(_ hardness: Float = 0.75) {
        super.init()
        createShader()
        set("Hardness", hardness)
    }
}
