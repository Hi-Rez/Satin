vertex VertexData vert( uint vertexID [[vertex_id]],
                                   constant Vertex *vertices [[buffer( VertexBufferVertices )]],
                                   constant VertexUniforms &vertexUniforms [[buffer( VertexBufferVertexUniforms )]])
{
    Vertex v = vertices[vertexID];
    VertexData out;
    out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * v.position;
    out.normal = normalize( vertexUniforms.normalMatrix * v.normal );
    out.uv = v.uv;
    return out;
}

