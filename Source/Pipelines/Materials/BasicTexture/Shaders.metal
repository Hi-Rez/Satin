fragment float4 basicTextureFragment(VertexData in [[stage_in]],
                                     constant BasicTextureUniforms &uniforms
                                     [[buffer(FragmentBufferMaterialUniforms)]]
                                     texture2d<float> tex [[texture(FragmentTextureCustom0)]],
                                     sampler texSampler [[sampler(FragmentSamplerCustom0)]]) {
    return uniforms.color * tex.sample(texSampler, in.uv);
}
