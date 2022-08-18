//
//  IcoSphereGenerator.c
//  Geometry-macOS
//
//  Created by Reza Ali on 6/4/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

#include "IcosahedronGenerator.h"

#include <malloc/_malloc.h>
#include <simd/simd.h>

GeometryData generateIcosahedronGeometryData(float radius, int res) {
    const float phi = (1.0 + sqrt(5)) * 0.5;
    const float r2 = radius * radius;
    const float den = (1.0 + (1.0 / pow(phi, 2.0)));
    const float h = sqrt(r2 / (den));
    const float w = h / phi;
        
    int vertices = 12;
    int triangles = 20;
    
    Vertex *vtx = (Vertex *)malloc(sizeof(Vertex) * vertices);
    TriangleIndices *ind = (TriangleIndices *)malloc(sizeof(TriangleIndices) * triangles);
    
    vtx[0].position = simd_make_float4(0.0, h, w, 1.0);
    vtx[1].position = simd_make_float4(0.0, h, -w, 1.0);
    vtx[2].position = simd_make_float4(0.0, -h, w, 1.0);
    vtx[3].position = simd_make_float4(0.0, -h, -w, 1.0);

    vtx[4].position = simd_make_float4(h, -w, 0.0, 1.0);
    vtx[5].position = simd_make_float4(h, w, 0.0, 1.0);
    vtx[6].position = simd_make_float4(-h, -w, 0.0, 1.0);
    vtx[7].position = simd_make_float4(-h, w, 0.0, 1.0);

    vtx[8].position = simd_make_float4(-w, 0.0, -h, 1.0);
    vtx[9].position = simd_make_float4(w, 0.0, -h, 1.0);
    vtx[10].position = simd_make_float4(-w, 0.0, h, 1.0);
    vtx[11].position = simd_make_float4(w, 0.0, h, 1.0);
    
    ind[0] = (TriangleIndices){ 0, 11, 5 };
    ind[1] = (TriangleIndices){ 0, 5, 1 };
    ind[2] = (TriangleIndices){ 0, 1, 7 };
    ind[3] = (TriangleIndices){ 0, 7, 10 };
    ind[4] = (TriangleIndices){ 0, 10, 11 };

    ind[5] = (TriangleIndices){ 1, 5, 9 };
    ind[6] = (TriangleIndices){ 5, 11, 4 };
    ind[7] = (TriangleIndices){ 11, 10, 2 };
    ind[8] = (TriangleIndices){ 10, 7, 6 };
    ind[9] = (TriangleIndices){ 7, 1, 8 };

    ind[10] = (TriangleIndices){ 3, 9, 4 };
    ind[11] = (TriangleIndices){ 3, 4, 2 };
    ind[12] = (TriangleIndices){ 3, 2, 6 };
    ind[13] = (TriangleIndices){ 3, 6, 8 };
    ind[14] = (TriangleIndices){ 3, 8, 9 };

    ind[15] = (TriangleIndices){ 4, 9, 5 };
    ind[16] = (TriangleIndices){ 2, 4, 11 };
    ind[17] = (TriangleIndices){ 6, 2, 10 };
    ind[18] = (TriangleIndices){ 8, 6, 7 };
    ind[19] = (TriangleIndices){ 9, 8, 1 };
    
    for(int r = 0; r < res; r++) {
        int newTriangles = triangles * 4;
        int newVertices = vertices + triangles * 3;
        vtx = (Vertex *)realloc(vtx, newVertices * sizeof(Vertex));
        TriangleIndices *newInd = (TriangleIndices *)malloc(newTriangles * sizeof(TriangleIndices));
        
        int j = vertices;
        int k = 0;
        for(int i = 0; i < triangles; i++) {
            TriangleIndices t = ind[i];
            const int i0 = t.i0;
            const int i1 = t.i1;
            const int i2 = t.i2;
            
            const Vertex v0 = vtx[i0];
            const Vertex v1 = vtx[i1];
            const Vertex v2 = vtx[i2];

            //a
            vtx[j].position = simd_make_float4(v0.position + v1.position)*0.5;
            uint32_t a = (uint32_t)j;
            j++;
            
            //b
            vtx[j].position = simd_make_float4(v1.position + v2.position)*0.5;
            uint32_t b = (uint32_t)j;
            j++;
            //c
            vtx[j].position = simd_make_float4(v2.position + v0.position)*0.5;
            uint32_t c = (uint32_t)j;
            j++;

            newInd[k] = (TriangleIndices){ i0, a, c };
            k++;
            newInd[k] = (TriangleIndices){ a, i1, b };
            k++;
            newInd[k] = (TriangleIndices){ a, b, c };
            k++;
            newInd[k] = (TriangleIndices){ c, b, i2 };
            k++;
        }

        free(ind);
        ind = newInd;
        triangles = newTriangles;
        vertices = newVertices;
    }
    
    for(int i = 0; i < vertices; i++) {
        const simd_float4 p = vtx[i].position;
        vtx[i].normal = simd_normalize(simd_make_float3(p.x, p.y, p.z));
        vtx[i].uv = simd_make_float2((atan2(p.x, p.z) + M_PI) / (2.0 * M_PI), acos(p.y) / M_PI);
    }
    
    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}
