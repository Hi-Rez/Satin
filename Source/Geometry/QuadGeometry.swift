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
        let hsize = size * 0.5
        self.primitiveType = .triangle
        vertexData = [
            Vertex(position: simd_make_float4(-hsize, -hsize, 0.0, 1.0), normal: simd_make_float3(0.0, 0.0, 1.0), uv: simd_make_float2(0.0, 1.0)),
            Vertex(position: simd_make_float4(hsize, -hsize, 0.0, 1.0), normal: simd_make_float3(0.0, 0.0, 1.0), uv: simd_make_float2(1.0, 1.0)),
            Vertex(position: simd_make_float4(-hsize, hsize, 0.0, 1.0), normal: simd_make_float3(0.0, 0.0, 1.0), uv: simd_make_float2(0.0, 0.0)),
            Vertex(position: simd_make_float4(hsize, hsize, 0.0, 1.0), normal: simd_make_float3(0.0, 0.0, 1.0), uv: simd_make_float2(1.0, 0.0))
        ]
        indexData = [0, 3, 2, 0, 1, 3]
    }
}
