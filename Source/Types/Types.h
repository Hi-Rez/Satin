//
//  Types.h
//  Satin
//
//  Created by Reza Ali on 6/4/20.
//

#ifndef Vertex_h
#define Vertex_h

#include <stdbool.h>
#include <simd/simd.h>

typedef struct {
    simd_float4 position;
    simd_float3 normal;
    simd_float2 uv;
} Vertex;

typedef struct {
    uint32_t i0;
    uint32_t i1;
    uint32_t i2;
} TriangleIndices;

typedef struct {
    int vertexCount;
    Vertex *vertexData;
    int indexCount;
    TriangleIndices *indexData;
} GeometryData;

void freeGeometryData( GeometryData geometry );

#endif /* Types_h */
