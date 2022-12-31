#include "Library/Map.metal"

typedef struct {
    int2 size;
    float2 range;
    int seed;
} RandomNoiseUniforms;

float rand2(float2 n) { return fract(sin(dot(n.xy, float2(12.9898, 78.233))) * 43758.5453); }
float rand3(float3 n) { return rand2(n.xy + fract(0.05 * n.z)); }

kernel void randomNoiseUpdate(
    uint2 gid [[thread_position_in_grid]],
    constant RandomNoiseUniforms &uniforms [[buffer(ComputeBufferUniforms)]],
    texture2d<float, access::write> tex [[texture(ComputeTextureCustom0)]])
{
    if (gid.x >= tex.get_width() || gid.y >= tex.get_height()) { return; }
    const float2 size = float2(tex.get_width(), tex.get_height()) - 1.0;
    const float2 uv = float2(gid) / size;

    const int seed = uniforms.seed;
    const float2 range = uniforms.range;

    const float r = map(rand3(float3(uv, seed)), 0.0, 1.0, range.x, range.y);
    const float g = map(rand3(float3(uv + 1.0, seed)), 0.0, 1.0, range.x, range.y);
    const float b = map(rand3(float3(uv - 1.0, seed)), 0.0, 1.0, range.x, range.y);
    const float a = map(rand3(float3(uv * float2(1.0, -1.0), seed)), 0.0, 1.0, range.x, range.y);

    tex.write(float4(r, g, b, a), gid);
}
