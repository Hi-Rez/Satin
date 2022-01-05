//
//  Bezier.h
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

#ifndef Bezier_h
#define Bezier_h

#include <stdio.h>
#include <simd/simd.h>

simd_float2 quadraticBezier2(float t, simd_float2 a, simd_float2 b, simd_float2 c);
simd_float2 cubicBezier2(float t, simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d);

simd_float3 quadraticBezier3(float t, simd_float3 a, simd_float3 b, simd_float3 c);
simd_float3 cubicBezier3(float t, simd_float3 a, simd_float3 b, simd_float3 c, simd_float3 d);

#endif /* Bezier_h */


