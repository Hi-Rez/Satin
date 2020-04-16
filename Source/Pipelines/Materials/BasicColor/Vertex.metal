vertex VertexData basicColorVertex( uint vertexID [[vertex_id]],
                                   constant Vertex *vertices [[buffer( VertexBufferVertices )]],
                                   constant VertexUniforms &vertexUniforms [[buffer( VertexBufferVertexUniforms )]])
{
    const float4 position = vertices[vertexID].position;
	VertexData out;
	out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * position;
	out.uv = vertices[vertexID].uv;
	out.normal = normalize( vertexUniforms.normalMatrix * vertices[vertexID].normal );
	return out;
}

