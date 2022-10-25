//
//  BasicColorMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class NormalColorMaterial: Material {
    public init(_ absolute: Bool = false) {
        super.init()
        set("Absolute", absolute)
    }

    public required init() {
        super.init()
        set("Absolute", false)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
