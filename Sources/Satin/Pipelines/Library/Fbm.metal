#include "Noise3D.metal"
#include "Noise2D.metal"

float fbm(float2 v, int octaves)
{
    float res = 0.0;
    float scale = 1.0;
    for (int i = 0; i < 8; i++) {
        if (i >= octaves) break;
        res += snoise(v) * scale;
        v *= float2(2.0, 2.0);
        scale *= 0.5;
    }
    return res;
}

float fbm(float3 v, int octaves)
{
    float res = 0.0;
    float scale = 1.0;
    for (int i = 0; i < 8; i++) {
        if (i >= octaves) break;
        res += snoise(v) * scale;
        v *= float3(2.0, 2.0, 2.0);
        scale *= 0.5;
    }
    return res;
}

float fbm_abs(float2 v, int octaves)
{
    float res = 0.0;
    float scale = 1.0;
    for (int i = 0; i < 8; i++) {
        if (i >= octaves) break;
        res += abs(snoise(v)) * scale;
        v *= float2(2.0, 2.0);
        scale *= 0.5;
    }
    return res;
}

float fbm_abs(float3 v, int octaves)
{
    float res = 0.0;
    float scale = 1.0;
    for (int i = 0; i < 8; i++) {
        if (i >= octaves) break;
        res += abs(snoise(v)) * scale;
        v *= float3(2.0, 2.0, 2.0);
        scale *= 0.5;
    }
    return res;
}
