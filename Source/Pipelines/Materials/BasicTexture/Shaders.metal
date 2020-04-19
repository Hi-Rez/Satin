fragment float4 basicTextureFragment(VertexData in [[stage_in]],
                                     texture2d<float> tex [[texture(FragmentTextureCustom0)]],
                                     sampler texSampler [[sampler(FragmentSamplerCustom0)]]) {
    return tex.sample(texSampler, in.uv);
}
