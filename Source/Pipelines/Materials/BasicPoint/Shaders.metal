vertex VertexData basicPointVertex(Vertex in[[stage_in]],
                 constant VertexUniforms &vertexUniforms[[buffer(VertexBufferVertexUniforms)]],
                 constant BasicPointUniforms &uniforms[[buffer(VertexBufferMaterialUniforms)]]) {
    VertexData out;
    out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * in.position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
    out.uv = in.uv;
    out.pointSize = uniforms.pointSize;
    return out;
}

fragment float4 basicPointFragment(
    VertexData in[[stage_in]],
    constant BasicPointUniforms &uniforms[[buffer(FragmentBufferMaterialUniforms)]]) {
    return uniforms.color;
}
