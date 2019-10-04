vertex VertexData basicColorVertex( uint vertexID [[vertex_id]],
                                   constant Vertex *vertices [[buffer( 0 )]],
                                   constant VertexUniforms &vertexUniforms [[buffer( 1 )]],
                                   constant ShadowUniforms &shadowUniforms [[buffer( 2 )]])
{
    const float4 position = vertices[vertexID].position;
	VertexData out;
	out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * position;
	out.uv = vertices[vertexID].uv;
	out.normal = normalize( vertexUniforms.normalMatrix * vertices[vertexID].normal );
    out.shadowPosition = shadowUniforms.shadowMatrix * vertexUniforms.modelMatrix * position;
	return out;
}
