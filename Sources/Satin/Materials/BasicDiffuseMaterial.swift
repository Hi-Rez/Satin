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
        set("Hardness", hardness)
    }

    public required init() {
        super.init()
        set("Hardness", 0.75)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
