#include "Pi.metal"

// https://www.shadertoy.com/view/ll2GD3
float3 palette(float t, float3 a, float3 b, float3 c, float3 d) {
    return a + b * cos(TWO_PI * (c * t + d));
}

float3 iridescence(float n) {
    return palette(n,
        float3(0.5, 0.5, 0.5),
        float3(0.5, 0.5, 0.5),
        float3(1.0, 1.0, 1.0),
        float3(0.0, 0.33, 0.67)
    );
}

float3 temperature(float n) {
    return palette(-n-0.5,
        float3(0.5, 0.5, 0.5),
        float3(0.5, 0.5, 0.5),
        float3(1.0, 1.0, 1.0),
        float3(0.0, 0.10, 0.20)
    );
}
