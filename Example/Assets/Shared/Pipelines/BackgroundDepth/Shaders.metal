typedef struct {
    float3 nearFarDelta;
} BackgroundDepthUniforms;

struct FragOut {
    float depth [[ depth( any ) ]];
};

static constexpr sampler s(mag_filter::linear, min_filter::linear);

fragment FragOut backgroundDepthFragment
(
    VertexData in [[stage_in]],
    constant BackgroundDepthUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    depth2d<float, access::sample> capturedDepthTexture [[ texture( FragmentTextureCustom0 ) ]]
)
{
    FragOut out;

    float z = capturedDepthTexture.sample(s, in.uv) + 0.01;
//    const float4x4 proj = uniforms.projection;
//    float sz = proj[2][2];
//    float sw = proj[3][2];
//    z = sz + sw / z;

    const float near = uniforms.nearFarDelta.x;
    const float far = uniforms.nearFarDelta.y;
    const float farMinusNear = uniforms.nearFarDelta.z;
    const float sz = near / farMinusNear;
    const float sw = (far * near) / farMinusNear;
    z = sz + sw / z;

    out.depth = z;

    return out;
}
