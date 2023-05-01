#include "Library/Random.metal"

typedef struct {
    float grainAmount; //slider,0,1,0.5
    float bloomAmount; //slider,0,4,1
    float grainIntensity;
    float time;
} BloomUniforms;

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

fragment float4 bloomFragment
(
    VertexData in [[stage_in]],
    constant BloomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> bgTex [[texture( FragmentTextureCustom0 )]],
    texture2d<float, access::sample> contentTex [[texture( FragmentTextureCustom1 )]],
    texture2d<float, access::sample> bloomTex [[texture( FragmentTextureCustom2 )]],
    texture3d<float> grainTex [[texture( FragmentTextureCustom3 )]]
)
{
    const float4 bgSample = bgTex.sample( s, in.uv );
    const float4 bloomSample = bloomTex.sample( s, in.uv );
    const float4 grainSample = getGrain(grainTex, in.position.xy, in.uv, uniforms.grainIntensity, uniforms.time);

    float4 contentSample = contentTex.sample( s, in.uv );
    contentSample.rgb += mix(0.0, grainSample.rgb * grainSample.a, contentSample.a * uniforms.grainAmount);

    float4 color = mix(bgSample, contentSample, contentSample.a);

    color.rgb += bloomSample.a * bloomSample.rgb * uniforms.bloomAmount;

    return color;
}





