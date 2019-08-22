//
//  Shaders.metal
//  Slate Shared
//
//  Created by Reza Ali on 7/19/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#include "../Library/Vertex.metal"
#include "../Library/VertexData.metal"
#include "../Library/VertexUniforms.metal"
#include "../Library/Uniforms.metal"

vertex VertexData basic_vertex(uint vertexID [[vertex_id]],
                                constant Vertex *vertices [[buffer(0)]],
                                constant VertexUniforms &uniforms [[buffer(1)]]) {
     VertexData out;
     out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * vertices[vertexID].position;
     out.uv = vertices[vertexID].uv;
     out.normal = normalize(uniforms.normalMatrix * vertices[vertexID].normal);
     return out;
 }

fragment float4 basic_fragment(VertexData in [[stage_in]],
                               constant Uniforms &uniforms [[buffer(0)]]) {
    return float4(in.uv, abs(sin(uniforms.color)), 1.0);
}
