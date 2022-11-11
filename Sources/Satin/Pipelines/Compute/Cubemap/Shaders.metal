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

kernel void cubemapUpdate(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex0 [[texture(ComputeTextureCustom0)]],
    texture2d<float, access::write> tex1 [[texture(ComputeTextureCustom1)]],
    texture2d<float, access::write> tex2 [[texture(ComputeTextureCustom2)]],
    texture2d<float, access::write> tex3 [[texture(ComputeTextureCustom3)]],
    texture2d<float, access::write> tex4 [[texture(ComputeTextureCustom4)]],
    texture2d<float, access::write> tex5 [[texture(ComputeTextureCustom5)]],
    texture2d<float, access::sample> ref [[texture(ComputeTextureCustom6)]],
    constant CubemapUniforms &uniforms [[buffer(ComputeBufferUniforms)]])
{
    if (gid.x >= tex0.get_width() || gid.y >= tex0.get_height()) { return; }

    constexpr sampler s(mag_filter::linear, min_filter::linear);
    const texture2d<float, access::write> tex[6] = { tex0, tex1, tex2, tex3, tex4, tex5 };

    const float2 size = float2(tex0.get_width(), tex0.get_height()) - 1.0;
    const float2 uv = float2(gid) / size;

    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;

    for (int face = 0; face < 6; face++) {
        const float4 rotation = rotations[face];
        const float3 dir = normalize(float3(ruv, 1.0)) * rotateAxisAngle(rotation.xyz, rotation.w);

        float theta = atan2(dir.x, dir.z);
        theta = (theta > 0 ? theta : (TWO_PI + theta)) / TWO_PI;
        const float phi = asin(dir.y);

        const float2 suv = float2(fract(theta + 0.5), 1.0 - (phi + HALF_PI) / PI);

        float3 color = ref.sample(s, suv).rgb;

        // HDR Tonemapping
        color = uniforms.toneMapped ? aces(color) : color;

        // Gamma Correction
        color = uniforms.gammaCorrected ? gamma(color) : color;

        tex[face].write(float4(color, 1.0), gid);
    }
}
