fragment float4 basicColorFragment( VertexData in [[stage_in]],
	constant BasicColorUniforms &uniforms [[buffer( 0 )]] )
{
	return uniforms.color;
}
