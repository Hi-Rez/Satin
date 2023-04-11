typedef struct {
	float4 color; // color
} LidarMeshUniforms;

typedef struct {
	float4 position [[position]];
} CustomVertexData;

vertex CustomVertexData lidarMeshShadowVertex( Vertex in [[stage_in]],
                                        constant VertexUniforms &vertexUniforms [[buffer( VertexBufferVertexUniforms )]] )
{
    CustomVertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * float4(in.position.xyz, 1.0);
    return out;
}

vertex CustomVertexData lidarMeshVertex( Vertex in [[stage_in]],
	constant VertexUniforms &vertexUniforms [[buffer( VertexBufferVertexUniforms )]] )
{
	CustomVertexData out;
	out.position = vertexUniforms.modelViewProjectionMatrix * float4(in.position.xyz, 1.0);
	return out;
}

fragment float4 lidarMeshFragment( CustomVertexData in [[stage_in]],
	constant LidarMeshUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
	return uniforms.color;
}
