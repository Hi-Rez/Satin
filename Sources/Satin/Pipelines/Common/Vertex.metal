vertex VertexData satinVertex(Vertex in [[stage_in]],
                              constant VertexUniforms &vertexUniforms
                              [[buffer(VertexBufferVertexUniforms)]]) {
    VertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
    out.uv = in.uv;
    out.pointSize = 2.0;
    return out;
}
