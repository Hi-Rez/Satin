#include "Library/Random.metal"

typedef struct {
    float cameraGrainIntensity;
    float time;
    float2 grainSize;
} PostUniforms;


fragment half4 postFragment
(
    VertexData in [[stage_in]],
    constant PostUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> contextTex [[texture( FragmentTextureCustom0 )]],
    texture3d<float, access::sample> grainTex [[texture( FragmentTextureCustom1 )]]
)
{
    const float2 uv = in.uv;
    const float time = uniforms.time;
    const float2 grainSize = uniforms.grainSize;
    const float cameraGrainIntensity = uniforms.cameraGrainIntensity;

    const float2 grainUV = fmod(in.position.xy, grainSize) / grainSize;
    const int2 grainCell = int2(in.position.xy/grainSize);
    const float3 noiseUV = float3(grainUV, time);
    const float2 noiseOffset = float2(random(noiseUV, 123 + grainCell.x), random(noiseUV, 234 + grainCell.y));
    const float3 guv = float3(fract(grainUV + noiseOffset), cameraGrainIntensity);

    constexpr sampler s = sampler( filter::linear );

    float4 grain = grainTex.sample(s, guv);
    float4 content = contextTex.sample(s, uv);
    content.rgb += mix(0.0, grain.rgb, content.a);

    return half4(content);
}
