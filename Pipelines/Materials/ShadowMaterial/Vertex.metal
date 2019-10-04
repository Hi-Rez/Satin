vertex float4 shadowVertex( uint vertexID [[vertex_id]],
                           constant Vertex *vertices [[buffer( 0 )]],
                           constant VertexUniforms &uniforms [[buffer( 1 )]],
                           constant ShadowUniforms &shadowUniforms [[buffer( 2 )]])
{	
	return shadowUniforms.shadowMatrix * uniforms.modelMatrix * vertices[vertexID].position;
}
