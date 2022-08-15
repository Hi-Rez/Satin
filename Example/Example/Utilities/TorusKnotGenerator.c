//
//  TorusKnotGenerator.c
//  Matcap-macOS
//
//  Created by Reza Ali on 6/2/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

#include "TorusKnotGenerator.h"

simd_float3 torusKnotGenerator(float t, float s, float R, float r, float c, float q, float p) {
    float theta = p * t;
    float phi = q * t;
    
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);
    
    float cosPhi = cos(phi);
    float sinPhi = sin(phi);
    
    const simd_float3 torus = simd_make_float3( (R + r * cosPhi) * cosTheta, (R + r * cosPhi) * sinTheta, r * sinPhi );
    const simd_float3 normal = simd_make_float3( cos(theta) * cos(phi), sin(theta) * cos(phi), sin(phi) );

    const simd_float3 tTheta = (1.0 + r * cosPhi) * simd_make_float3(-sinTheta, cosTheta, 0.0);
    const simd_float3 tPhi = r * simd_make_float3(-sinPhi * cosTheta, -sinPhi * sinTheta, cosPhi);
    const simd_float3 tangentPrime = simd_normalize(p * tTheta + q * tPhi);
    const simd_float3 biTangent = simd_cross(tangentPrime, normal);

    return torus + (c * cos(s) * normal + c * sin(s) * biTangent);
}
