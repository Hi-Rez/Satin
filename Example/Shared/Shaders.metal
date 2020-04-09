//
//  Shaders.metal
//  Example Shared
//
//  Created by Reza Ali on 8/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct {
    vector_float4 position;
    vector_float2 uv;
    vector_float3 normal;
} Vertex;

typedef struct {
    vector_float4 position [[position]];
    vector_float2 uv;
    vector_float3 normal;
} VertexData;

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
} VertexUniforms;

vertex VertexData basic_vertex(uint vertexID [[vertex_id]],
                                constant Vertex *vertices [[buffer(0)]],
                                constant VertexUniforms &uniforms [[buffer(1)]]) {
     VertexData out;
     out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * vertices[vertexID].position;
     out.uv = vertices[vertexID].uv;
     out.normal = normalize(uniforms.normalMatrix * vertices[vertexID].normal);
     return out;
 }

fragment float4 basic_fragment(VertexData in [[stage_in]]) {
    return float4(in.uv, 0.0, 1.0);
}
