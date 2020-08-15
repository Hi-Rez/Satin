typedef struct {
    float4 position [[position]];
    float3 viewPosition;
    float3 normal;
    float2 uv;
    float pointSize [[point_size]];
} DiffuseVertexData;

vertex DiffuseVertexData basicDiffuseVertex(Vertex in [[stage_in]],
                                     constant VertexUniforms &vertexUniforms
                                     [[buffer(VertexBufferVertexUniforms)]]) {
                                     
    const float3 normal = normalize( vertexUniforms.normalMatrix * in.normal );
    const float4 screenSpaceNormal = vertexUniforms.viewMatrix * float4( normal, 0.0 );
    DiffuseVertexData out;
    const float4 viewPosition = vertexUniforms.modelViewMatrix * in.position;
    out.viewPosition = viewPosition.xyz;
    out.position = vertexUniforms.projectionMatrix * viewPosition;
    out.normal = normalize( screenSpaceNormal.xyz ),
    out.uv = in.uv;
    out.pointSize = 2.0;
    return out;
}

fragment float4 basicDiffuseFragment(DiffuseVertexData in [[stage_in]],
                                    constant BasicDiffuseUniforms &uniforms
                                    [[buffer(FragmentBufferMaterialUniforms)]]) {
    const float3 pos = in.viewPosition;
    const float3 dx = dfdx( pos );
    const float3 dy = dfdy( pos );
    const float3 normal = normalize( cross( dx, dy ) );
    const float soft = dot( in.normal, float3( 0.0, 0.0, 1.0 ) );
    const float hard = dot( normal, float3( 0.0, 0.0, -1.0 ) );
    return float4( float3( mix( soft, hard, uniforms.hardness ) ), 1.0 );
}
