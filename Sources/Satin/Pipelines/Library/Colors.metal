#include "Pi.metal"

// https://www.shadertoy.com/view/ll2GD3
float3 palette(float t, float3 a, float3 b, float3 c, float3 d)
{
    return a + b * cos(TWO_PI * (c * t + d));
}

float3 iridescence(float n)
{
    return palette(n, float3(0.5, 0.5, 0.5), float3(0.5, 0.5, 0.5), float3(1.0, 1.0, 1.0), float3(0.0, 0.33, 0.67));
}

float3 temperature(float n)
{
    return palette(-n - 0.5, float3(0.5, 0.5, 0.5), float3(0.5, 0.5, 0.5), float3(1.0, 1.0, 1.0), float3(0.0, 0.10, 0.20));
}

float3 spectrum(float f)
{
    f = f * 3.0 - 1.5;
    return pow(saturate(float3(-f, 1.0 - abs(f), f)), 1.0 / 2.2);
}

// https://www.shadertoy.com/view/3dXfWH
float3 scatter(float g, float3 c) // gradient, color
{
    float3 g3 = float3(g);
    float3 g1 = pow(c, g3);
    float3 g2 = 1.0 - pow(1.0 - c, 1.0 - g3);

    float3 a = g1 * (1.0 - g1);
    float3 b = g2 * (1.0 - g2);

    return 4.5 * mix(a, b, g3);
}

// Copyright 2019 Google LLC.
// SPDX-License-Identifier: Apache-2.0

// Polynomial approximation in GLSL for the Turbo colormap
// Original LUT: https://gist.github.com/mikhailov-work/ee72ba4191942acecc03fe6da94fc73f

// Authors:
//   Colormap Design: Anton Mikhailov (mikhailov@google.com)
//   GLSL Approximation: Ruofei Du (ruofei@google.com)
//   MSL Approximation: Reza Ali (reza@hi-rez.io)

float3 turbo(float x)
{
    const float4 kRedfloat4 = float4(0.13572138, 4.61539260, -42.66032258, 132.13108234);
    const float4 kGreenfloat4 = float4(0.09140261, 2.19418839, 4.84296658, -14.18503333);
    const float4 kBluefloat4 = float4(0.10667330, 12.64194608, -60.58204836, 110.36276771);
    const float2 kRedfloat2 = float2(-152.94239396, 59.28637943);
    const float2 kGreenfloat2 = float2(4.27729857, 2.82956604);
    const float2 kBluefloat2 = float2(-89.90310912, 27.34824973);

    x = saturate(x);
    float4 v4 = float4(1.0, x, x * x, x * x * x);
    float2 v2 = v4.zw * v4.z;
    return float3(
        dot(v4, kRedfloat4) + dot(v2, kRedfloat2),
        dot(v4, kGreenfloat4) + dot(v2, kGreenfloat2),
        dot(v4, kBluefloat4) + dot(v2, kBluefloat2));
}
