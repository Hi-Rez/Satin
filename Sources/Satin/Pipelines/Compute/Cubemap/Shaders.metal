#include "Library/Pi.metal"
#include "Library/Rotate.metal"
#include "Library/Tonemapping/Aces.metal"
#include "Library/Gamma.metal"

static constant float4 rotations[6] = {
    float4(0.0, 1.0, 0.0, HALF_PI),         // 0 - X+
    float4(0.0, 1.0, 0.0, -HALF_PI),        // 1 - X-
    float4(1.0, 0.0, 0.0, -HALF_PI),        // 2 - Y+
    float4(1.0, 0.0, 0.0, HALF_PI),         // 3 - Y-
    float4(0.0, 0.0, 1.0, 0.0),             // 4 - Z+
    float4(0.0, 1.0, 0.0, PI)               // 5 - Z-
};

typedef struct {
    int2 size;
    bool toneMapped;     // toggle,false
    bool gammaCorrected; // toggle,false
} CubemapUniforms;

constexpr sampler cubeSampler(mag_filter::linear, min_filter::linear, address::repeat);

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
    const float2 tuv = float2((atan2(dir.z, dir.x) / TWO_PI) + 0.5, acos(dir.y) / PI);
    
    float3 color = ref.sample(cubeSampler, tuv).rgb;

    // HDR Tonemapping
    color = uniforms.toneMapped ? aces(color) : color;

    // Gamma Correction
    color = uniforms.gammaCorrected ? gamma(color) : color;

    tex.write(float4(color, 1.0), gid);
}
