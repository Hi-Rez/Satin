vertex VertexData satinVertex(const Vertex in [[stage_in]],
                              constant VertexUniforms &vertexUniforms
                              [[buffer(VertexBufferVertexUniforms)]]) {
    VertexData out;
    out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * in.position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
    out.uv = in.uv;
    return out;
}

