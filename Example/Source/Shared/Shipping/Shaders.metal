//
//  Shaders.metal
//  Boring
//
//  Created by Reza Ali on 2/9/22.
//

// File for Metal kernel and shader functions

#include "Helper.metal"

vertex VertexData normalColorVertex(Vertex in [[stage_in]],
                              constant VertexUniforms &vertexUniforms
                              [[buffer(VertexBufferVertexUniforms)]]) {
    VertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
    out.uv = in.uv;
    return out;
}

fragment float4 normalColorFragment(VertexData in [[stage_in]],
                                    constant NormalColorUniforms &uniforms
                                    [[buffer(FragmentBufferMaterialUniforms)]]) {
    return uniforms.color * float4(uniforms.absolute ? abs(in.normal) : in.normal, 1.0);
}

