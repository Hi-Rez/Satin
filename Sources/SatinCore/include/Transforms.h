//
//  Transforms.h
//  Satin
//
//  Created by Reza Ali on 1/13/22.
//

#ifndef Transforms_h
#define Transforms_h

#include <simd/simd.h>

simd_float4x4 translationMatrixf(float x, float y, float z);
simd_float4x4 translationMatrix3f(simd_float3 p);

simd_float4x4 scaleMatrixf(float x, float y, float z);
simd_float4x4 scaleMatrix3f(simd_float3 p);

simd_float4x4 frustrumMatrixf(float left, float right, float bottom, float top, float near,
                              float far);
simd_float4x4 orthographicMatrixf(float left, float right, float bottom, float top, float near,
                                  float far);
simd_float4x4 perspectiveMatrixf(float fov, float aspect, float near, float far);

simd_float4x4 lookAtMatrix3f(simd_float3 eye, simd_float3 at, simd_float3 up);

#endif /* Transforms_h */
