//
//  QuadGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/19/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import simd

open class QuadGeometry: Geometry {
    public init(size: Float = 2) {
        super.init()
        self.setupData(size: size)
    }

    func setupData(size: Float) {
        var geometryData = generateQuadGeometryData(size)
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
