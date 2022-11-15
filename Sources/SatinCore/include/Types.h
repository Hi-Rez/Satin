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
    simd_float3 min;
    simd_float3 max;
} Bounds;

typedef struct {
    simd_float3 origin;
    simd_float3 direction;
} Ray;

typedef struct {
    int count;
    int capacity;
    simd_float2 *data;
} Polyline2D;

typedef struct {
    int count;
    simd_float3 *data;
} Polyline3D;

typedef struct {
    uint32_t i0;
    uint32_t i1;
    uint32_t i2;
} TriangleIndices;

typedef struct {
    int count;
    uint32_t *data;
} TriangleFaceMap;

TriangleFaceMap createTriangleFaceMap(void);
void freeTriangleFaceMap(TriangleFaceMap *map);

typedef struct {
    int vertexCount;
    Vertex *vertexData;
    int indexCount;
    TriangleIndices *indexData;
} GeometryData;

GeometryData createGeometryData(void);
void freeGeometryData(GeometryData *data);

void copyGeometryVertexData(GeometryData *dest, GeometryData *src, int start, int end);
void copyGeometryIndexData(GeometryData *dest, GeometryData *src, int start, int end);
void copyGeometryData(GeometryData *dest, GeometryData *src);

void addTrianglesToGeometryData(GeometryData *dest, TriangleIndices *triangles, int triangleCount);

void combineGeometryData(GeometryData *dest, GeometryData *src);
void combineAndOffsetGeometryData(GeometryData *dest, GeometryData *src, simd_float3 offset);
void combineAndScaleGeometryData(GeometryData *dest, GeometryData *src, simd_float3 scale);
void combineAndScaleAndOffsetGeometryData(GeometryData *dest, GeometryData *src, simd_float3 scale,
                                          simd_float3 offset);
void combineAndTransformGeometryData(GeometryData *dest, GeometryData *src,
                                     simd_float4x4 transform);

void computeNormalsOfGeometryData(GeometryData *data);
void reverseFacesOfGeometryData(GeometryData *data);

void transformVertices(Vertex *vertices, int vertexCount, simd_float4x4 transform);
void transformGeometryData(GeometryData *data, simd_float4x4 transform);

void deindexGeometryData(GeometryData *dest, GeometryData *src);
void unrollGeometryData(GeometryData *dest, GeometryData *src);

void combineGeometryDataAndTriangleFaceMap(GeometryData *destGeo, GeometryData *srcGeo, TriangleFaceMap *destMap, TriangleFaceMap *srcMap, uint32_t offset);

#endif /* Types_h */
