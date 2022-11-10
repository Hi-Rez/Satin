#include "../../Library/Pi.metal"
#include "../../Library/Rotate.metal"

static constant float4 rotations[6] = {
    float4(0.0, 1.0, 0.0, HALF_PI),
    float4(0.0, 1.0, 0.0, -HALF_PI),
    float4(1.0, 0.0, 0.0, -HALF_PI),
    float4(1.0, 0.0, 0.0, HALF_PI),
    float4(0.0, 0.0, 1.0, 0.0),
    float4(0.0, 1.0, 0.0, PI)
};

#define WORLD_UP float3(0.0, 1.0, 0.0)
#define WORLD_FORWARD float3(0.0, 0.0, 1.0)
#define DELTA_PHI (TWO_PI / 360.0)
#define DELTA_THETA (HALF_PI / 90.0)

typedef struct {
    int2 size;
} DiffuseIBLUniforms;

constexpr sampler cubeSampler(mag_filter::linear, min_filter::linear);

kernel void diffuseIBLUpdate(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex0 [[texture(ComputeTextureCustom0)]],
    texture2d<float, access::write> tex1 [[texture(ComputeTextureCustom1)]],
    texture2d<float, access::write> tex2 [[texture(ComputeTextureCustom2)]],
    texture2d<float, access::write> tex3 [[texture(ComputeTextureCustom3)]],
    texture2d<float, access::write> tex4 [[texture(ComputeTextureCustom4)]],
    texture2d<float, access::write> tex5 [[texture(ComputeTextureCustom5)]],
    texturecube<float, access::sample> ref [[texture(ComputeTextureCustom6)]],
    constant DiffuseIBLUniforms &uniforms [[buffer(ComputeBufferUniforms)]])
{
    if (gid.x >= tex0.get_width() || gid.y >= tex0.get_height()) { return; }

    const texture2d<float, access::write> tex[6] = { tex0, tex1, tex2, tex3, tex4, tex5 };
    const float2 size = float2(tex0.get_width(), tex0.get_height()) - 1.0;
    const float2 uv = float2(gid) / size;

    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;

    for (int face = 0; face < 6; face++) {
        float3 irradiance = 0.0;

        const float4 rotation = rotations[face];
        float3 N = normalize(float3(ruv, 1.0) * rotateAxisAngle(rotation.xyz, rotation.w));
        float3 UP = abs(N.z) < 0.999 ? WORLD_FORWARD : WORLD_UP;
        const float3 RIGHT = normalize(cross(UP, N));
        UP = cross(N, RIGHT);

        uint sampleCount = 0u;

        for (float phi = 0.0; phi < TWO_PI; phi += DELTA_PHI) {
            const float sinPhi = sin(phi);
            const float cosPhi = cos(phi);
            for (float theta = 0.0; theta < HALF_PI; theta += DELTA_THETA) {
                // spherical to cartesian (in tangent space)
                const float sinTheta = sin(theta);
                const float cosTheta = cos(theta);

                const float3 tempVec = cosPhi * RIGHT + sinPhi * UP;
                const float3 sampleVector = cosTheta * N + sinTheta * tempVec;

                irradiance += ref.sample(cubeSampler, sampleVector).rgb * cosTheta * sinTheta;
                sampleCount++;
            }
        }
        irradiance = PI * irradiance / float(sampleCount);
        tex[face].write(float4(irradiance, 1.0), gid);
    }
}
