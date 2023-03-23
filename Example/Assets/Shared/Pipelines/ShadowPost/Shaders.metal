typedef struct {
    float4 color; //color
    float2 nearFar;
} ShadowPostUniforms;

fragment float4 shadowPostFragment
(
    VertexData in [[stage_in]],
    constant ShadowPostUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float> colorTex [[texture( FragmentTextureCustom0 )]],
    depth2d<float, access::sample> depthTex [[texture( FragmentTextureCustom1 )]]
)
{
    const float2 uv = in.uv;
    const float near = uniforms.nearFar.x;
    const float far = uniforms.nearFar.y;
    const float nearMinusFar = near - far;

    constexpr sampler s = sampler( filter::linear );
    
    const float depthSample = depthTex.sample(s, uv);
    const float linearDepth = -depthSample * far / nearMinusFar;

    float4 colorSample = colorTex.sample(s, uv);
    colorSample.rgb = saturate(1.0 - linearDepth);
    colorSample.a *= linearDepth;
    return colorSample * uniforms.color;
}
