vertex VertexData basicColorVertex( uint vertexID [[vertex_id]],
	constant Vertex *vertices [[buffer( 0 )]],
	constant VertexUniforms &uniforms [[buffer( 1 )]] )
{
	VertexData out;
	out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * vertices[vertexID].position;
	out.uv = vertices[vertexID].uv;
	out.normal = normalize( uniforms.normalMatrix * vertices[vertexID].normal );
	return out;
}