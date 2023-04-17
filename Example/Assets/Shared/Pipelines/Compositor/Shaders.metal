#include "Library/Random.metal"

typedef struct {
    float cameraGrainIntensity;
    float time;
    float2 grainSize;
} CompositorUniforms;

fragment float4 compositorFragment
(
    VertexData in [[stage_in]],
    constant CompositorUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float> contextTexture [[texture( FragmentTextureCustom0 )]],
    texture3d<float> grainTexture [[texture( FragmentTextureCustom1 )]],
    depth2d<float> contentDepthTexture [[texture( FragmentTextureCustom2 )]],
    texture2d<float> backgroundTexture [[texture( FragmentTextureCustom3 )]],
    texture2d<float> alphaTexture [[ texture( FragmentTextureCustom4 ) ]],
    depth2d<float> dilatedDepthTexture [[ texture( FragmentTextureCustom5 ) ]]
)
{
    constexpr sampler s = sampler( filter::linear );

    const float2 uv = in.uv;
    const float time = uniforms.time;
    const float2 grainSize = uniforms.grainSize;
    const float cameraGrainIntensity = uniforms.cameraGrainIntensity;

    const float2 grainUV = fmod(in.position.xy, grainSize) / grainSize;
    const int2 grainCell = int2(in.position.xy/grainSize);
    const float3 noiseUV = float3(grainUV, time);
    const float2 noiseOffset = float2(random(noiseUV, 123 + grainCell.x), random(noiseUV, 234 + grainCell.y));
    const float3 guv = float3(fract(grainUV + noiseOffset), cameraGrainIntensity);
    const float4 grain = grainTexture.sample(s, guv);

    const float4 backgroundSample = backgroundTexture.sample(s, uv);
    float4 contentSample = contextTexture.sample(s, uv);
    const float contentDepthSample = contentDepthTexture.sample(s, uv);

    const float alphaSample = alphaTexture.sample(s, uv).r;
    const float dilatedDepthSample = dilatedDepthTexture.sample(s, uv);

    contentSample.rgb += mix(0.0, grain.rgb, contentSample.a);

    float4 color = mix(backgroundSample, contentSample, contentSample.a);

    color = mix(color, backgroundSample, step(contentDepthSample, dilatedDepthSample) * alphaSample);

    return color;
}
