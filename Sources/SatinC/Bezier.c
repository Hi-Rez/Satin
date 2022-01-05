//
//  Bezier.c
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

#include "Bezier.h"

simd_float2 quadraticBezier2(float t, simd_float2 a, simd_float2 b, simd_float2 c)
{
    float oneMinusT = 1.0 - t;
    return oneMinusT * oneMinusT * a + 2.0 * oneMinusT * t * b + t * t * c;
}

simd_float3 quadraticBezier3(float t, simd_float3 a, simd_float3 b, simd_float3 c)
{
    float oneMinusT = 1.0 - t;
    return oneMinusT * oneMinusT * a + 2.0 * oneMinusT * t * b + t * t * c;
}


simd_float2 cubicBezier2(float t, simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d)
{
    float oneMinusT = 1.0 - t;
    return oneMinusT * oneMinusT * oneMinusT * a + 3.0 * oneMinusT * oneMinusT * t * b + 3.0 * oneMinusT * t * t * c + t * t * t * d;
}

simd_float3 cubicBezier3(float t, simd_float3 a, simd_float3 b, simd_float3 c, simd_float3 d)
{
    float oneMinusT = 1.0 - t;
    return oneMinusT * oneMinusT * oneMinusT * a + 3.0 * oneMinusT * oneMinusT * t * b + 3.0 * oneMinusT * t * t * c + t * t * t * d;
}
