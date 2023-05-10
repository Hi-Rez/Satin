//
//  Hermite.c
//
//
//  Created by Reza Ali on 5/4/23.
//

#include "Hermite.h"

simd_float3 hermite3(simd_float3 m0, simd_float3 a, simd_float3 b, simd_float3 m1, float t)
{
    const float t2 = t * t;
    const float t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1.0) * a + (t3 - 2 * t2 + t) * m0 + (-2 * t3 + 3 * t2) * b +
           (t3 - t2) * m1;
}
