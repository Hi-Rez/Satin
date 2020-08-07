//
//  Generators.c
//  Satin
//
//  Created by Reza Ali on 6/5/20.
//

#include <malloc/_malloc.h>
#include <simd/simd.h>

#include "Generators.h"
#include "Geometry.h"

GeometryData generateIcoSphereGeometryData(float radius, int res) {
    const float phi = (1.0 + sqrt(5)) * 0.5;
    const float r2 = radius * radius;
    const float den = (1.0 + (1.0 / pow(phi, 2.0)));
    const float h = sqrt(r2 / (den));
    const float w = h / phi;

    int vertices = 12;
    int triangles = 20;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

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

    for (int r = 0; r < res; r++) {
        int newTriangles = triangles * 4;
        int newVertices = vertices + triangles * 3;
        vtx = (Vertex *)realloc(vtx, newVertices * sizeof(Vertex));
        TriangleIndices *newInd = (TriangleIndices *)malloc(newTriangles * sizeof(TriangleIndices));

        int j = vertices;
        int k = 0;
        simd_float3 pos;
        for (int i = 0; i < triangles; i++) {
            TriangleIndices t = ind[i];
            const int i0 = t.i0;
            const int i1 = t.i1;
            const int i2 = t.i2;

            const Vertex v0 = vtx[i0];
            const Vertex v1 = vtx[i1];
            const Vertex v2 = vtx[i2];

            // a
            pos = simd_make_float3(v0.position + v1.position) * 0.5;
            pos = simd_normalize(pos) * radius;
            vtx[j].position = simd_make_float4(pos, 1.0);
            uint32_t a = (uint32_t)j;
            j++;

            // b
            pos = simd_make_float3(v1.position + v2.position) * 0.5;
            pos = simd_normalize(pos) * radius;
            vtx[j].position = simd_make_float4(pos, 1.0);
            uint32_t b = (uint32_t)j;
            j++;
            // c
            pos = simd_make_float3(v2.position + v0.position) * 0.5;
            pos = simd_normalize(pos) * radius;
            vtx[j].position = simd_make_float4(pos, 1.0);
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

    for (int i = 0; i < vertices; i++) {
        const simd_float4 p = vtx[i].position;
        vtx[i].normal = simd_normalize(simd_make_float3(p.x, p.y, p.z));
        vtx[i].uv = simd_make_float2((atan2(p.x, p.z) + M_PI) / (2.0 * M_PI), acos(p.y) / M_PI);
    }

    return (GeometryData){
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateSquircleGeometryData(float size, float p, int angularResolution,
                                          int radialResolution) {
    float r = size * 0.5;
    int angular = angularResolution > 2 ? angularResolution : 3;
    int radial = radialResolution > 1 ? radialResolution : 2;

    int perLoop = angular + 1;
    int vertices = radial * perLoop;
    int triangles = angular * 2.0 * radial;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int triIndex = 0;
    for (int j = 0; j < radial; j++) {
        float k = j / (float)(radial - 1);
        float radius = map(j, 0.0, (radial - 1), 0.0, r);
        for (int i = 0; i <= angular; i++) {
            float t = i / (float)angular;
            float theta = 2.0 * M_PI * t;
            float cost = cos(theta);
            float sint = sin(theta);
            float den = pow(fabs(cost), p) + pow(fabs(sint), p);
            float phi = 1.0 / pow(den, 1.0 / p);
            float x = radius * phi * cost;
            float y = radius * phi * sint;

            int index = j * perLoop + i;
            vtx[index].position = simd_make_float4(x, y, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            vtx[index].uv = simd_make_float2(t, k);

            if (j != (radial - 1) && i != angular) {
                int currLevel = j * perLoop;
                int nextLevel = (j + 1) * perLoop;

                int curr = i;
                int next = (i + 1);

                int i0 = curr + currLevel;
                int i1 = next + currLevel;
                int i2 = curr + nextLevel;
                int i3 = next + nextLevel;

                ind[triIndex] = (TriangleIndices){ i0, i2, i3 };
                triIndex++;
                ind[triIndex] = (TriangleIndices){ i0, i3, i1 };
                triIndex++;
            }
        }
    }

    return (GeometryData){
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateRoundedRectGeometryData(float width, float height, float radius,
                                             int angularResolution, int edgeXResolution,
                                             int edgeYResolution, int radialResolution) {
    float twoPi = M_PI * 2.0;
    float halfPi = M_PI * 0.5;

    int angular = angularResolution > 2 ? angularResolution : 3;
    int radial = radialResolution > 1 ? radialResolution : 2;
    int edgeX = edgeXResolution > 1 ? edgeXResolution : 2;
    edgeX += edgeX % 2 == 0 ? 1 : 0;
    int edgeY = edgeYResolution > 1 ? edgeYResolution : 2;
    edgeY += edgeY % 2 == 0 ? 1 : 0;
    int edgeYHalf = ceil(((float)edgeY + 0.5) / 2.0);

    int perLoop = (angular - 2) * 4 + edgeX * 2 + edgeY + edgeYHalf * 2;
    int vertices = perLoop * radial;
    int triangles = 2.0 * perLoop * (radial - 1) - 2.0 * (radial - 1);

    //    printf("per loop: %d\n", perLoop);

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int index = 0;

    float widthHalf = width * 0.5;
    float heightHalf = height * 0.5;

    float minDim = widthHalf > heightHalf ? widthHalf : heightHalf;
    radius = radius > minDim ? minDim : radius;

    for (int j = 0; j < radial; j++) {
        float n = (float)j / (float)(radial - 1);

        simd_float2 start = simd_make_float2(widthHalf, 0.0);
        simd_float2 end = simd_make_float2(widthHalf, heightHalf - radius);
        for (int i = 0; i < edgeYHalf; i++) {
            float t = (float)i / (float)(edgeYHalf - 1);
            simd_float2 pos = simd_mix(start, end, t);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            //            printf("angle: %d, %f -- edge 0\n", index, angle);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
        // 4

        // corner 0
        for (int i = 1; i < angular-1; i++) {
            float t = (float)i / (float)(angular - 1);
            float theta = t * halfPi;
            float x = radius * cos(theta);
            float y = radius * sin(theta);
            simd_float2 pos = simd_make_float2(widthHalf - radius + x, heightHalf - radius + y);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            //            printf("angle: %d, %f -- corner 0\n", index, angle);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
        // 8 -- 12

        start = simd_make_float2(widthHalf - radius, heightHalf);
        end = simd_make_float2(-widthHalf + radius, heightHalf);
        for (int i = 0; i < edgeX; i++) {
            float t = (float)i / (float)(edgeX - 1);
            simd_float2 pos = simd_mix(start, end, t);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            //            printf("angle: %d, %f -- edge 1\n", index, angle);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
        // 8 -- 20

        // corner 1
        for (int i = 1; i < angular-1; i++) {
            float t = (float)i / (float)(angular - 1);
            float theta = t * halfPi + halfPi;
            float x = radius * cos(theta);
            float y = radius * sin(theta);
            simd_float2 pos = simd_make_float2(-widthHalf + radius + x, heightHalf - radius + y);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            //            printf("angle: %d, %f -- corner 1\n", index, angle);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
        // 8 -- 28

        start = simd_make_float2(-widthHalf, heightHalf - radius);
        end = simd_make_float2(-widthHalf, -heightHalf + radius);
        for (int i = 0; i < edgeY; i++) {
            float t = (float)i / (float)(edgeY - 1);
            simd_float2 pos = simd_mix(start, end, t);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            //            printf("angle: %d, %f -- edge 2\n", index, angle);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
        // 8 -- 36

        // corner 2
        for (int i = 1; i < angular-1; i++) {
            float t = (float)i / (float)(angular - 1);
            float theta = t * halfPi + M_PI;
            float x = radius * cos(theta);
            float y = radius * sin(theta);
            simd_float2 pos = simd_make_float2(-widthHalf + radius + x, -heightHalf + radius + y);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            //            printf("angle: %d, %f -- corner 2\n", index, angle);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
        // 8 -- 44

        start = simd_make_float2(-widthHalf + radius, -heightHalf);
        end = simd_make_float2(widthHalf - radius, -heightHalf);
        for (int i = 0; i < edgeX; i++) {
            float t = (float)i / (float)(edgeX - 1);
            simd_float2 pos = simd_mix(start, end, t);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            //            printf("angle: %d, %f -- edge 3\n", index, angle);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
        // 8 -- 52

        // corner 3
        for (int i = 1; i < angular-1; i++) {
            float t = (float)i / (float)(angular - 1);
            float theta = t * halfPi + 1.5 * M_PI;
            float x = radius * cos(theta);
            float y = radius * sin(theta);
            simd_float2 pos = simd_make_float2(widthHalf - radius + x, -heightHalf + radius + y);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            angle = isZero(angle) ? twoPi : angle;
            //            printf("angle: %d, %f %f -- corner 3\n", index, angle, theta);
            float uvx = angle / twoPi;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }

        start = simd_make_float2(widthHalf, -heightHalf + radius);
        end = simd_make_float2(widthHalf, 0.0);
        for (int i = 0; i < edgeYHalf; i++) {
            float t = (float)i / (float)(edgeYHalf - 1);
            simd_float2 pos = simd_mix(start, end, t);
            vtx[index].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[index].normal = simd_make_float3(0.0, 0.0, 1.0);
            float angle = angle2(pos);
            angle = isZero(angle) ? twoPi : angle;
            //            printf("angle: %d, %f -- edge 4\n", index, angle);
            float uvx = angle / twoPi;
            uvx = (i == (edgeYHalf - 1)) ? 1.0 : uvx;
            float uvy = n;
            vtx[index].uv = simd_make_float2(uvx, uvy);
            index++;
        }
    }

    int triIndex = 0;
    for (int j = 0; j < radial; j++) {
        for (int i = 0; i < perLoop; i++) {

            if (((j + 1) != radial) && ((i + 1) != perLoop)) {
                int currLoop = j * perLoop;
                int nextLoop = (j + 1) * perLoop;

                int i0 = currLoop + i;
                int i1 = currLoop + i + 1;

                int i2 = nextLoop + i;
                int i3 = nextLoop + i + 1;

                ind[triIndex] = (TriangleIndices){ i0, i2, i3 };
                triIndex++;
                ind[triIndex] = (TriangleIndices){ i0, i3, i1 };
                triIndex++;
            }
        }
    }

    return (GeometryData){
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateExtrudedRoundedRectGeometryData(float width, float height, float depth,
                                                     float radius, int angularResolution,
                                                     int edgeXResolution, int edgeYResolution,
                                                     int edgeZResolution, int radialResolution) {
    GeometryData faceData =
        generateRoundedRectGeometryData(width, height, radius, angularResolution, edgeXResolution,
                                        edgeYResolution, radialResolution);

    GeometryData result = {
        .vertexCount = 0, .vertexData = NULL, .indexCount = 0, .indexData = NULL
    };

    float depthHalf = depth * 0.5;
    combineAndOffsetGeometryData(&result, &faceData, simd_make_float3(0.0, 0.0, depthHalf));

    // Calculations from RoundedRectGeometry
    int angular = angularResolution > 2 ? angularResolution : 3;
    int radial = radialResolution > 1 ? radialResolution : 2;
    int edgeX = edgeXResolution > 1 ? edgeXResolution : 2;
    edgeX += edgeX % 2 == 0 ? 1 : 0;
    int edgeY = edgeYResolution > 1 ? edgeYResolution : 2;
    edgeY += edgeY % 2 == 0 ? 1 : 0;
    int edgeYHalf = ceil(((float)edgeY + 0.5) / 2.0);
    int edgeZ = edgeZResolution > 0 ? edgeZResolution : 1;

    int perLoop = (angular - 2) * 4 + edgeX * 2 + edgeY + edgeYHalf * 2;
    int vertices = perLoop * radial;
        
    GeometryData edgeData = {
        .vertexCount = 0, .vertexData = NULL, .indexCount = 0, .indexData = NULL
    };

    copyGeometryVertexData(&edgeData, &result, vertices - perLoop, perLoop);
    
    int extrudeTriangles = (perLoop - 1) * 2 * edgeZ;
    TriangleIndices *ind = (TriangleIndices *)malloc(extrudeTriangles * sizeof(TriangleIndices));

    GeometryData extrudeData = {
        .vertexCount = 0, .vertexData = NULL, .indexCount = extrudeTriangles, .indexData = ind
    };

    int triIndex = 0;
    float zInc = depth / edgeZ;
    for (int j = 0; j <= edgeZ; j++) {
        float z = j * zInc;
        float uvx = (float)j / (float)edgeZ;
        int currLoop = j * perLoop;
        int nextLoop = (j + 1) * perLoop;
        for (int i = 0; i < perLoop; i++) {
            float uvy = (float)i/(float)perLoop;
            edgeData.vertexData[i].uv = simd_make_float2(uvx, uvy);
            edgeData.vertexData[i].position.z -= z;
            
            int prev = i - 1;
            prev = prev < 0 ? (perLoop - 1) : prev;
            int curr = i;
            int next = (i + 1) % perLoop;
            
            simd_float4 prevPos = edgeData.vertexData[prev].position;
            simd_float4 currPos = edgeData.vertexData[curr].position;
            simd_float4 nextPos = edgeData.vertexData[next].position;
            
            simd_float4 d0 = prevPos - currPos;
            simd_float4 d1 = currPos - nextPos;
            
            d0 += d1;
            edgeData.vertexData[i].normal = simd_normalize(simd_make_float3(-d0.y, d0.x, 0.0));
            
            if((j != edgeZ) && ((i + 1) != perLoop)) {
                int i0 = currLoop + curr;
                int i1 = currLoop + next;

                int i2 = nextLoop + curr;
                int i3 = nextLoop + next;

                ind[triIndex] = (TriangleIndices){ i0, i2, i3 };
                triIndex++;
                ind[triIndex] = (TriangleIndices){ i0, i3, i1 };
                triIndex++;
            }
        }
        combineGeometryData(&extrudeData, &edgeData);
    }
        
    combineGeometryData(&result, &extrudeData);
    reverseFacesOfGeometryData(&faceData);
    combineAndOffsetGeometryData(&result, &faceData, simd_make_float3(0.0, 0.0, -depthHalf));

    freeGeometryData(&edgeData);
    freeGeometryData(&extrudeData);
    freeGeometryData(&faceData);

    return result;
}
