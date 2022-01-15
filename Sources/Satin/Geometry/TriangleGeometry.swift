//
//  TriangleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class TriangleGeometry: Geometry {
    public init(size: Float = 1) {
        super.init()
        self.setupData(size: size)
    }

    func setupData(size: Float) {
        var geometryData = generateTriangleGeometryData(size)
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
