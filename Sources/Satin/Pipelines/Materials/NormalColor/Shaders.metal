typedef struct {
    bool absolute; // toggle
} NormalColorUniforms;

fragment float4 normalColorFragment(VertexData in [[stage_in]],
    constant NormalColorUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{    
    const float3 normal = normalize(in.normal);
    return float4(mix(normal, abs(normal), float(uniforms.absolute)), 1.0);
}
