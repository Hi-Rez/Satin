vertex VertexData vert( uint vertexID [[vertex_id]],
                                   constant Vertex *vertices [[buffer( VertexBufferVertices )]],
                                   constant VertexUniforms &vertexUniforms [[buffer( VertexBufferVertexUniforms )]],
                                   constant ShadowUniforms &shadowUniforms [[buffer( VertexBufferShadowUniforms )]])
{
    const float4 position = vertices[vertexID].position;
	VertexData out;
	out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * position;
	out.uv = vertices[vertexID].uv;
	out.normal = normalize( vertexUniforms.normalMatrix * vertices[vertexID].normal );
    out.shadowPosition = shadowUniforms.shadowMatrix * vertexUniforms.modelMatrix * position;
	return out;
}

