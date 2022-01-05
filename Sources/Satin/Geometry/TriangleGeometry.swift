//
//  TriangleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class TriangleGeometry: Geometry {
    public override init() {
        super.init()
        self.setupData()
    }
    
    func setupData() {
        let twoPi: Float = Float.pi * 2.0
        var angle: Float = 0.0
        vertexData.append(
            Vertex(
                position: simd_make_float4(sin(angle), cos(angle), 0.0, 1.0),
                normal: normalize(simd_make_float3(0.0, 0.0, 1.0)),
                uv: simd_make_float2(0, 0)
            )
        )
        
        angle = twoPi / 3.0
        vertexData.append(
            Vertex(
                position: simd_make_float4(sin(angle), cos(angle), 0.0, 1.0),
                normal: normalize(simd_make_float3(0.0, 0.0, 1.0)),
                uv: simd_make_float2(0, 1)
            )
        )
        
        angle = 2.0 * twoPi / 3.0
        vertexData.append(
            Vertex(
                position: simd_make_float4(sin(angle), cos(angle), 0.0, 1.0),
                normal: normalize(simd_make_float3(0.0, 0.0, 1.0)),
                uv: simd_make_float2(1, 0)
            )
        )
        
        indexData.append(UInt32(0))
        indexData.append(UInt32(2))
        indexData.append(UInt32(1))
    }
}
