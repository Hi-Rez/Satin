vertex VertexData basicDiffuseVertex(Vertex in [[stage_in]],
                                     constant VertexUniforms &vertexUniforms
                                     [[buffer(VertexBufferVertexUniforms)]]) {
                                     
    const float3 normal = normalize(vertexUniforms.normalMatrix * in.normal);
    const float4 screenSpaceNormal = vertexUniforms.viewMatrix * float4(normal, 0.0);
    VertexData out;
    out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * in.position;
    out.normal =  normalize(screenSpaceNormal.xyz),
    out.uv = in.uv;
    out.pointSize = 2.0;
    return out;
}

fragment float4 basicDiffuseFragment(VertexData in [[stage_in]],
                                    constant BasicDiffuseUniforms &uniforms
                                    [[buffer(FragmentBufferMaterialUniforms)]]) {
    return float4( float3( dot( in.normal, float3( 0.0, 0.0, 1.0 ) ) ), 1.0);
}
