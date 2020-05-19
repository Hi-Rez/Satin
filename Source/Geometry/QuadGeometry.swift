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
        self.setup(size: size)
    }
    
    func setup(size: Float) {
        let hsize = size * 0.5
        self.primitiveType = .triangle
        vertexData = [
            Vertex(simd_make_float4(-hsize, -hsize, 0.0, 1.0), simd_make_float2(0.0, 1.0), simd_make_float3(0.0, 0.0, 1.0)),
            Vertex(simd_make_float4(hsize, -hsize, 0.0, 1.0), simd_make_float2(1.0, 1.0), simd_make_float3(0.0, 0.0, 1.0)),
            Vertex(simd_make_float4(-hsize, hsize, 0.0, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, 1.0)),
            Vertex(simd_make_float4(hsize, hsize, 0.0, 1.0), simd_make_float2(1.0, 0.0), simd_make_float3(0.0, 0.0, 1.0))
        ]
        indexData = [0, 1, 2, 1, 3, 2]
    }
}
