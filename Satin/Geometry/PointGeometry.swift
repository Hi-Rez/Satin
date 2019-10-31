//
//  PointGeometry.swift
//  Satin
//
//  Created by Reza Ali on 10/9/19.
//

import simd

open class PointGeometry: Geometry {
    public override init() {
        super.init()
        self.setup()
    }

    func setup() {
        primitiveType = .point
        vertexData.append(
            Vertex(
                SIMD4<Float>(0.0, 0.0, 0.0, 1.0),
                SIMD2<Float>(0.0, 0.0),
                SIMD3<Float>(0.0, 0.0, 1.0)
            )
        )
    }
}
