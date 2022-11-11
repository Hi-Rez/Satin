#include "Poisson.metal"
#include "Random.metal"

float calculateShadow(float4 shadowPosition, float4 position, depth2d<float> shadowTexture)
{
    float2 xy = shadowPosition.xy;
    xy = xy * 0.5 + 0.5;
    xy.y = 1.0 - xy.y;

    float lightFactor = 1.0;
    float bias = 0.006;
    constexpr sampler s(coord::normalized, filter::linear, address::clamp_to_edge, compare_func::less);
    const float current_sample = (shadowPosition.z - bias) / shadowPosition.w;
    const float2 shadowTextureSize =
        float2(shadowTexture.get_width(), shadowTexture.get_height()) * 1.0;
    float shadow_sample = 0.0;
    const int total = 4;
    for (int i = 0; i < total; i++) {
        int index = int(16.0 * random(floor(position.xyz * 1000.0), i)) % 16;
        index *= 2;
        const float2 poisson =
            float2(poissonDisk16[index], poissonDisk16[index + 1]) / shadowTextureSize;
        shadow_sample += shadowTexture.sample(s, xy + poisson);
    }
    shadow_sample /= float(total);
    if (current_sample > shadow_sample) { lightFactor *= 0.0; }
    return lightFactor;
}
