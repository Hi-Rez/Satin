typedef struct {
    float4 color; // color
} BasicColorUniforms;

fragment float4 basicColorFragment(VertexData in [[stage_in]],
    constant BasicColorUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    return uniforms.color;
}
