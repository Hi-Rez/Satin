vertex float4 shadowVertex( uint vertexID [[vertex_id]],
                           constant Vertex *vertices [[buffer( VertexBufferVertices )]],
                           constant VertexUniforms &uniforms [[buffer( VertexBufferVertexUniforms )]],
                           constant ShadowUniforms &shadowUniforms [[buffer( VertexBufferShadowUniforms )]])
{	
	return shadowUniforms.shadowMatrix * uniforms.modelMatrix * vertices[vertexID].position;
}
