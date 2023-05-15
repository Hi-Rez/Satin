#include "Library/Random.metal"

typedef struct {
    float grainAmount; //slider,0,1,0.5
    float grainIntensity;
    float time;
} PostUniforms;

static constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

float4 getGrain(texture3d<float> grainTex, float2 fragPos, float2 uv, float grainIntensity, float time) {
    const float2 grainSize = float2(grainTex.get_width(), grainTex.get_height());

    const float2 grainUV = fmod(fragPos, grainSize) / grainSize;
    const int2 grainCell = int2(fragPos / grainSize);

    const float3 noiseUV = float3(grainUV, time);
    const float2 noiseOffset = float2(random(noiseUV, 123 + grainCell.x), random(noiseUV, 234 + grainCell.y));

    const float3 guv = float3(fract(grainUV + noiseOffset), grainIntensity);

    return grainTex.sample(s, guv);
}

fragment float4 postFragment
(
    VertexData in [[stage_in]],
    constant PostUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> realTex [[texture( FragmentTextureCustom0 )]],
    texture2d<float, access::sample> virtualTex [[texture( FragmentTextureCustom1 )]],
    texture2d<float, access::sample> depthMaskTex [[texture( FragmentTextureCustom2 )]],
    texture3d<float> grainTex [[texture( FragmentTextureCustom3 )]]
)
{
    const float depthMask = depthMaskTex.sample(s, in.uv).r;
    const float4 realSample = realTex.sample(s, in.uv);
    const float4 grainSample = getGrain(grainTex, in.position.xy, in.uv, uniforms.grainIntensity, uniforms.time);

    float4 virtualSample = virtualTex.sample(s, in.uv);
    virtualSample.rgb += mix(0.0, grainSample.rgb * grainSample.a, virtualSample.a * uniforms.grainAmount);

    float4 finalColor = mix(realSample, virtualSample, virtualSample.a * depthMask);
    return finalColor;

//    return float4(depthMask, realSample.g, virtualSample.b, 1.0);
}





