#include "Library/Pi.metal"
#include "Library/Rotate.metal"
#include "Library/Tonemapping/Aces.metal"
#include "Library/Gamma.metal"

static constant float4 rotations[6] = {
    float4(0.0, 1.0, 0.0, HALF_PI),
    float4(0.0, 1.0, 0.0, -HALF_PI),
    float4(1.0, 0.0, 0.0, -HALF_PI),
    float4(1.0, 0.0, 0.0, HALF_PI),
    float4(0.0, 0.0, 1.0, 0.0),
    float4(0.0, 1.0, 0.0, PI)
};

typedef struct {
    int2 size;
    bool toneMapped;     // toggle,false
    bool gammaCorrected; // toggle,false
} CubemapUniforms;

constexpr sampler cubeSampler(mag_filter::linear, min_filter::linear);

kernel void cubemapUpdate(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex [[texture(ComputeTextureCustom0)]],
    texture2d<float, access::sample> ref [[texture(ComputeTextureCustom1)]],
    constant CubemapUniforms &uniforms [[buffer(ComputeBufferUniforms)]],
    constant uint &face [[buffer(ComputeBufferCustom0)]])
{
    if (gid.x >= tex.get_width() || gid.y >= tex.get_height()) { return; }

    const float2 size = float2(tex.get_width(), tex.get_height()) - 1.0;
    const float2 uv = float2(gid) / size;

    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;
    
    const float4 rotation = rotations[face];
    const float3 dir = normalize(float3(ruv, 1.0)) * rotateAxisAngle(rotation.xyz, rotation.w);

    float theta = atan2(dir.x, dir.z);
    theta = (theta > 0 ? theta : (TWO_PI + theta)) / TWO_PI;
    const float phi = asin(dir.y);

    const float2 suv = float2(fract(theta + 0.5), 1.0 - (phi + HALF_PI) / PI);
    
    float3 color = ref.sample(cubeSampler, suv).rgb;

    // HDR Tonemapping
    color = uniforms.toneMapped ? aces(color) : color;

    // Gamma Correction
    color = uniforms.gammaCorrected ? gamma(color) : color;

    tex.write(float4(color, 1.0), gid);
}
