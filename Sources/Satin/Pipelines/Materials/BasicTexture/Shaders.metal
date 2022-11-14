typedef struct {
    float4 color; // color
    bool flipped;
} BasicTextureUniforms;

fragment float4 basicTextureFragment(VertexData in [[stage_in]],
    constant BasicTextureUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]],
    texture2d<float> tex [[texture(FragmentTextureCustom0)]],
    sampler texSampler [[sampler(FragmentSamplerCustom0)]])
{
    float2 uv = in.uv;
    uv.y = mix(uv.y, 1.0 - uv.y, uniforms.flipped);
    return uniforms.color * tex.sample(texSampler, uv);
}
