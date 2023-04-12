typedef struct {
    float3 nearFarDelta;
} MatteUniforms;

struct FragOut {
    float4 color [[color( 0 )]];
    float depth [[depth( any )]];
};

static constexpr sampler s(mag_filter::linear, min_filter::linear);

fragment FragOut matteFragment
(
    VertexData in [[stage_in]],
    constant MatteUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float> alphaTexture [[ texture(FragmentTextureCustom0) ]],
    depth2d<float> depthTexture [[ texture(FragmentTextureCustom1) ]]
)
{
    const float2 uv = in.uv;

    FragOut out;
    out.color = alphaTexture.sample(s, uv);

    const float z = depthTexture.sample(s, uv);
    const float near = uniforms.nearFarDelta.x;
    const float far = uniforms.nearFarDelta.y;
    const float farMinusNear = uniforms.nearFarDelta.z;
    const float sz = near / farMinusNear;
    const float sw = (far * near) / farMinusNear;
    out.depth = z > 0.0 ? (sz + sw / z) : 0.0;
    return out;
}
