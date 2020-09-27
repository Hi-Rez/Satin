typedef struct {
    float time;
    float3 appResolution;
} BackgroundUniforms;

fragment float4 backgroundFragment( VertexData in [[stage_in]],
    constant BackgroundUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> capturedImageTextureY [[ texture(FragmentTextureCustom0) ]],
    texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(FragmentTextureCustom1) ]])
{    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );
    
    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.uv).r,
                          capturedImageTextureCbCr.sample(colorSampler, in.uv).rg, 1.0);
    
    // Return converted RGB color
    return ycbcrToRGBTransform * ycbcr;
}

