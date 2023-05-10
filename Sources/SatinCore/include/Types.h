//
//  Types.h
//  Satin
//
//  Created by Reza Ali on 6/4/20.
//

#ifndef Types_h
#define Types_h

#import <stdbool.h>
#import <simd/simd.h>

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct Vertex {
    simd_float4 position;
    simd_float3 normal;
    simd_float2 uv;
} Vertex;

typedef struct Bounds {
    simd_float3 min;
    simd_float3 max;
} Bounds;

typedef struct Rectangle {
    simd_float2 min;
    simd_float2 max;
} Rectangle;

typedef struct Ray {
    simd_float3 origin;
    simd_float3 direction;
} Ray;

typedef struct Polyline2D {
    int count;
    int capacity;
    simd_float2 *data;
} Polyline2D;

typedef struct Polyline3D {
    int count;
    simd_float3 *data;
} Polyline3D;

typedef struct TriangleIndices {
    uint32_t i0;
    uint32_t i1;
    uint32_t i2;
} TriangleIndices;

typedef struct TriangleFaceMap {
    int count;
    uint32_t *data;
} TriangleFaceMap;

typedef struct GeometryData {
    int vertexCount;
    Vertex *vertexData;
    int indexCount;
    TriangleIndices *indexData;
} GeometryData;

typedef struct BVHNode {
    Bounds aabb;
    uint32_t leftFirst;
    uint32_t triCount;
} BVHNode;

typedef struct BVH {
    GeometryData geometry;
    BVHNode *nodes;
    simd_float3 *centroids;
    simd_float3 *positions;
    TriangleIndices *triangles;
    uint32_t *triIDs;
    uint32_t nodesUsed;
    bool useSAH;
} BVH;

TriangleFaceMap createTriangleFaceMap(void);
void freeTriangleFaceMap(TriangleFaceMap *map);

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

void combineGeometryDataAndTriangleFaceMap(GeometryData *destGeo, GeometryData *srcGeo,
                                           TriangleFaceMap *destMap, TriangleFaceMap *srcMap);

#if defined(__cplusplus)
}
#endif

#endif /* Types_h */
