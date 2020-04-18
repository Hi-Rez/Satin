//
//  SkyboxGeometry.swift
//  Satin
//
//  Created by Reza Ali on 4/16/20.
//  Reference: https://metalbyexample.com/reflection-and-refraction/ Warren Moore

import simd

open class SkyboxGeometry: Geometry {
    public override init() {
        super.init()
        self.setup()
    }

    func setup() {
        self.primitiveType = .triangle
        vertexData = [
            // +Y
            Vertex(simd_make_float4(-0.5, 0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, -1.0, 0.0)),
            Vertex(simd_make_float4(0.5, 0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, -1.0, 0.0)),
            Vertex(simd_make_float4(0.5, 0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, -1.0, 0.0)),
            Vertex(simd_make_float4(-0.5, 0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, -1.0, 0.0)),
            // -Y
            Vertex(simd_make_float4(-0.5, -0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 1.0, 0.0)),
            Vertex(simd_make_float4(0.5, -0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 1.0, 0.0)),
            Vertex(simd_make_float4(0.5, -0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 1.0, 0.0)),
            Vertex(simd_make_float4(-0.5, -0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 1.0, 0.0)),
            // +Z
            Vertex(simd_make_float4(-0.5, -0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, -1.0)),
            Vertex(simd_make_float4(0.5, -0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, -1.0)),
            Vertex(simd_make_float4(0.5, 0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, -1.0)),
            Vertex(simd_make_float4(-0.5, 0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, -1.0)),
            // -Z
            Vertex(simd_make_float4(0.5, -0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, 1.0)),
            Vertex(simd_make_float4(-0.5, -0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, 1.0)),
            Vertex(simd_make_float4(-0.5, 0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, 1.0)),
            Vertex(simd_make_float4(0.5, 0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(0.0, 0.0, 1.0)),
            // -X
            Vertex(simd_make_float4(-0.5, -0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(1.0, 0.0, 0.0)),
            Vertex(simd_make_float4(-0.5, -0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(1.0, 0.0, 0.0)),
            Vertex(simd_make_float4(-0.5, 0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(1.0, 0.0, 0.0)),
            Vertex(simd_make_float4(-0.5, 0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(1.0, 0.0, 0.0)),
            // +X
            Vertex(simd_make_float4(0.5, -0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(-1.0, 0.0, 0.0)),
            Vertex(simd_make_float4(0.5, -0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(-1.0, 0.0, 0.0)),
            Vertex(simd_make_float4(0.5, 0.5, -0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(-1.0, 0.0, 0.0)),
            Vertex(simd_make_float4(0.5, 0.5, 0.5, 1.0), simd_make_float2(0.0, 0.0), simd_make_float3(-1.0, 0.0, 0.0))
        ]

        indexData = [0, 3, 2, 2, 1, 0,
                     4, 7, 6, 6, 5, 4,
                     8, 11, 10, 10, 9, 8,
                     12, 15, 14, 14, 13, 12,
                     16, 19, 18, 18, 17, 16,
                     20, 23, 22, 22, 21, 20]
    }
}
