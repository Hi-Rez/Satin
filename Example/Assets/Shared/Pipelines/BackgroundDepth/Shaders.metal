typedef struct {
    float3 nearFarDelta;
} BackgroundDepthUniforms;

struct FragOut {
    float4 color [[color( 0 )]];
    float depth [[depth( any )]];
};

static constexpr sampler s(mag_filter::linear, min_filter::linear);

fragment FragOut backgroundDepthFragment( VertexData in [[stage_in]],
    constant BackgroundDepthUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> capturedImageTextureY [[ texture(FragmentTextureCustom0) ]],
    texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(FragmentTextureCustom1) ]],
    depth2d<float, access::sample> capturedDepthTexture [[ texture(FragmentTextureCustom2) ]])
{
    const float2 uv = in.uv;
    const float4x4 ycbcrToRGBTransform = float4x4(float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                                                  float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                                                  float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                                                  float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f));

    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(s, uv).r,
                          capturedImageTextureCbCr.sample(s, uv).rg,
                          1.0);

    float z = capturedDepthTexture.sample(s, uv);

    const float near = uniforms.nearFarDelta.x;
    const float far = uniforms.nearFarDelta.y;
    const float farMinusNear = uniforms.nearFarDelta.z;
    const float sz = near / farMinusNear;
    const float sw = (far * near) / farMinusNear;
    z = sz + sw / z;

    FragOut out;
    out.color = ycbcrToRGBTransform * ycbcr;
    out.depth = z;
    return out;
}
