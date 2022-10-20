//
//  Matrix.c
//  Satin
//
//  Created by Reza Ali on 1/13/22.
//

#include "Helpers.h"
#include "Transforms.h"
#include <stdio.h>

simd_float4x4 translationMatrixf(float x, float y, float z) {
    simd_float4x4 result = matrix_identity_float4x4;
    result.columns[3] = simd_make_float4(x, y, z, 1.0);
    return result;
}

simd_float4x4 translationMatrix3f(simd_float3 p) {
    simd_float4x4 result = matrix_identity_float4x4;
    result.columns[3] = simd_make_float4(p, 1.0);
    return result;
}

simd_float4x4 scaleMatrixf(float x, float y, float z) {
    simd_float4x4 result = matrix_identity_float4x4;
    result.columns[0].x = x;
    result.columns[1].y = y;
    result.columns[2].z = z;
    return result;
}

simd_float4x4 scaleMatrix3f(simd_float3 p) {
    simd_float4x4 result = matrix_identity_float4x4;
    result.columns[0].x = p.x;
    result.columns[1].y = p.y;
    result.columns[2].z = p.z;
    return result;
}

simd_float4x4 orthographicMatrixf(float left, float right, float bottom, float top, float near,
                                  float far) {
    simd_float4x4 result = matrix_identity_float4x4;

    result.columns[0].x = 2.0 / (right - left);
    result.columns[1].y = 2.0 / (top - bottom);
    result.columns[2].z = -1.0 / (far - near);

    result.columns[3].x = (left + right) / (left - right);
    result.columns[3].y = (top + bottom) / (bottom - top);
    result.columns[3].z = near / (near - far);

    return result;
}

simd_float4x4 frustrumMatrixf(float left, float right, float bottom, float top, float near,
                              float far) {
    const float rightMinusLeft = right - left;
    const float topMinusBottom = top - bottom;
    const float farMinusNear = far - near;
    const float twoTimesNear = 2.0 * near;

    const float col0x = twoTimesNear / rightMinusLeft;
    const float col1y = twoTimesNear / topMinusBottom;
    const float col2x = (right + left) / rightMinusLeft;
    const float col2y = (top + bottom) / topMinusBottom;
    const float col2z = near / farMinusNear;
    const float col3z = (far * near) / farMinusNear;

    const simd_float4 col0 = simd_make_float4(col0x, 0.0, 0.0, 0.0);
    const simd_float4 col1 = simd_make_float4(0.0, col1y, 0.0, 0.0);
    const simd_float4 col2 = simd_make_float4(col2x, col2y, col2z, -1.0);
    const simd_float4 col3 = simd_make_float4(0.0, 0.0, col3z, 0.0);

    return simd_matrix(col0, col1, col2, col3);
}

simd_float4x4 perspectiveMatrixf(float fov, float aspect, float near, float far) {
    const float angle = degToRad(0.5 * fov);

    const float sy = 1.0 / tanf(angle);
    const float sx = sy / aspect;
    const float farMinusNear = far - near;
    const float sz = near / farMinusNear;
    const float sw = (far * near) / farMinusNear;

    const simd_float4 col0 = simd_make_float4(sx, 0.0, 0.0, 0.0);
    const simd_float4 col1 = simd_make_float4(0.0, sy, 0.0, 0.0);
    const simd_float4 col2 = simd_make_float4(0.0, 0.0, sz, -1.0);
    const simd_float4 col3 = simd_make_float4(0.0, 0.0, sw, 0.0);

    return simd_matrix(col0, col1, col2, col3);
}

simd_float4x4 lookAtMatrix3f(simd_float3 eye, simd_float3 at, simd_float3 up) {
    simd_float4x4 result = matrix_identity_float4x4;

    const simd_float3 zAxis = simd_normalize(at - eye);
    const simd_float3 xAxis = simd_normalize(simd_cross(up, zAxis));
    const simd_float3 yAxis = simd_normalize(simd_cross(zAxis, xAxis));

    result.columns[0].x = xAxis.x;
    result.columns[0].y = xAxis.y;
    result.columns[0].z = xAxis.z;

    result.columns[1].x = yAxis.x;
    result.columns[1].y = yAxis.y;
    result.columns[1].z = yAxis.z;

    result.columns[2].x = zAxis.x;
    result.columns[2].y = zAxis.y;
    result.columns[2].z = zAxis.z;

    result.columns[3].x = eye.x;
    result.columns[3].y = eye.y;
    result.columns[3].z = eye.z;

    return result;
}
