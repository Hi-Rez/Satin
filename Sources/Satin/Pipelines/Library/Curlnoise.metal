#include "Noise3D.metal"

float3 snoisefloat3(float3 x)
{
    float s = snoise(float3(x));
    float s1 = snoise(float3(x.y - 19.1, x.z + 33.4, x.x + 47.2));
    float s2 = snoise(float3(x.z + 74.2, x.x - 124.5, x.y + 99.4));
    float3 c = float3(s, s1, s2);
    return c;
}

float3 curlNoise(float3 p)
{
    const float e = .1;
    float3 dx = float3(e, 0.0, 0.0);
    float3 dy = float3(0.0, e, 0.0);
    float3 dz = float3(0.0, 0.0, e);

    float3 p_x0 = snoisefloat3(p - dx);
    float3 p_x1 = snoisefloat3(p + dx);
    float3 p_y0 = snoisefloat3(p - dy);
    float3 p_y1 = snoisefloat3(p + dy);
    float3 p_z0 = snoisefloat3(p - dz);
    float3 p_z1 = snoisefloat3(p + dz);

    float x = p_y1.z - p_y0.z - p_z1.y + p_z0.y;
    float y = p_z1.x - p_z0.x - p_x1.z + p_x0.z;
    float z = p_x1.y - p_x0.y - p_y1.x + p_y0.x;

    const float divisor = 1.0 / (2.0 * e);
    return normalize(float3(x, y, z) * divisor);
}
