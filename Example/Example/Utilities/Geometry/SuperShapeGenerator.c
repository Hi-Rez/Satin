//
//  SuperShape.c
//  SuperShapes
//
//  Created by Reza Ali on 9/7/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

#include "SuperShapeGenerator.h"

#include "Geometry.h"

#include <malloc/_malloc.h>
#include <simd/simd.h>

float superShape(float theta, float a, float b, float m, float n1, float n2, float n3) {
    const float aInv = 1.0 / a;
    const float bInv = 1.0 / b;
    const float thetaOverFour = theta / 4.0;
    const float angle = m * thetaOverFour;
    const float a0 = pow(fabs(aInv * cos(angle)), n2);
    const float b0 = pow(fabs(bInv * sin(angle)), n3);
    return pow(a0 + b0, -1.0 / n1);
}

GeometryData generateSuperShapeGeometryData(float r1, float a1, float b1, float m1, float n11,
                                            float n21, float n31, float r2, float a2, float b2, float m2,
                                            float n12, float n22, float n32, int resTheta,
                                            int resPhi) {

    int vertices = (resTheta + 1) * (resPhi + 1);
    int triangles = (resTheta * resPhi) * 2;

    Vertex *vtx = (Vertex *)malloc(sizeof(Vertex) * vertices);
    TriangleIndices *ind = (TriangleIndices *)malloc(sizeof(TriangleIndices) * triangles);

    int triIndex = 0;
    const float halfPi = M_PI * 0.5;
    for (int j = 0; j <= resTheta; j++) {
        const float v = map(j, 0, resTheta, 0.0, 1.0);
        const float theta = map(j, 0, resTheta, -M_PI, M_PI);
        const float _r1 = superShape(theta, a1, b1, m1, n11, n21, n31);

        const float cosTheta = cos(theta);
        const float sinTheta = sin(theta);

        for (int i = 0; i <= resPhi; i++) {

            const int index = j * (resTheta + 1) + i;

            const float u = map(i, 0, resPhi, 0.0, 1.0);
            const float phi = map(i, 0, resPhi, -halfPi, halfPi);
            const float _r2 = superShape(phi, a2, b2, m2, n12, n22, n32);

            const float cosPhi = cos(phi);
            const float sinPhi = sin(phi);

            const float x = r1 * _r1 * cosTheta * r2 * _r2 * cosPhi;
            const float y = r1 * _r1 * sinTheta * r2 * _r2 * cosPhi;
            const float z = r2 * _r2 * sinPhi;

            //            const float x = 2.0 * u - 1.0;
            //            const float y = 2.0 * v - 1.0;
            //            const float z = 0.0;

            vtx[index].position = simd_make_float4(x, y, z, 1.0);
            vtx[index].uv = simd_make_float2(u, v);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 0.0);

            const int indexNext = (j + 1) * (resTheta + 1) + i;

            if (j < resTheta && i < resPhi) {
                uint32_t a = (uint32_t)index;
                uint32_t b = (uint32_t)indexNext;
                uint32_t c = (uint32_t)a + 1;
                uint32_t d = (uint32_t)b + 1;

                ind[triIndex++] = (TriangleIndices){ a, b, c };
                ind[triIndex++] = (TriangleIndices){ b, d, c };
            }
        }
    }

    GeometryData data = (GeometryData){
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };

    computeNormalsOfGeometryData(&data);

    return data;
}
