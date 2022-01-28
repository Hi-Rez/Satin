//
//  BasicColorMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class NormalColorMaterial: Material {
    var absolute = BoolParameter("Absolute", .toggle)

    public init(_ absolute: Bool = false) {
        super.init()
        createShader()
        set("Absolute", absolute)
    }
}
