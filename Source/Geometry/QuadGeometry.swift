//
//  QuadGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/19/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import simd

open class QuadGeometry: Geometry {
    public override init() {
        super.init()
        self.setup()
    }
    
    func setup() {
        self.primitiveType = .triangleStrip
        vertexData.append(
            Vertex(
                SIMD4<Float>(-1.0, -1.0, 0.0, 1.0),
                SIMD2<Float>(0.0, 1.0),
                SIMD3<Float>(0.0, 0.0, 1.0)
            )
        )
        vertexData.append(
            Vertex(
                SIMD4<Float>(1.0, -1.0, 0.0, 1.0),
                SIMD2<Float>(1.0, 1.0),
                SIMD3<Float>(0.0, 0.0, 1.0)
            )
        )
        vertexData.append(
            Vertex(
                SIMD4<Float>(-1.0, 1.0, 0.0, 1.0),
                SIMD2<Float>(0.0, 0.0),
                SIMD3<Float>(0.0, 0.0, 1.0)
            )
        )
        vertexData.append(
            Vertex(
                SIMD4<Float>(1.0, 1.0, 0.0, 1.0),
                SIMD2<Float>(1.0, 0.0),
                SIMD3<Float>(0.0, 0.0, 1.0)
            )
        )
    }
}
