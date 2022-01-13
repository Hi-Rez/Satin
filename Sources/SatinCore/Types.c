//
//  Types.c
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

#include <malloc/_malloc.h>
#include <string.h>

#include "Geometry.h"
#include "Types.h"

void freeTriangleFaceMap(TriangleFaceMap *map) {
    if (map->count <= 0 && map->data == NULL) { return; }
    free(map->data);
    map->count = 0;
}

void freeGeometryData(GeometryData *data) {
    if (data->vertexCount <= 0 && data->vertexData == NULL) { return; }
    free(data->vertexData);
    data->vertexCount = 0;

    if (data->indexCount <= 0 && data->indexData == NULL) { return; }
    free(data->indexData);
    data->indexCount = 0;
}

void combineIndexGeometryData(GeometryData *dest, GeometryData *src,
                              int destPreCombineVertexCount) {
    if (src->indexCount > 0) {
        if (dest->indexCount > 0) {
            int totalCount = src->indexCount + dest->indexCount;
            dest->indexData = realloc(dest->indexData, totalCount * sizeof(TriangleIndices));
            memcpy(dest->indexData + dest->indexCount, src->indexData,
                   src->indexCount * sizeof(TriangleIndices));
            if (destPreCombineVertexCount > 0) {
                for (int i = dest->indexCount; i < totalCount; i++) {
                    dest->indexData[i].i0 += destPreCombineVertexCount;
                    dest->indexData[i].i1 += destPreCombineVertexCount;
                    dest->indexData[i].i2 += destPreCombineVertexCount;
                }
            }
            dest->indexCount += src->indexCount;
        } else {
            dest->indexData = (TriangleIndices *)malloc(sizeof(TriangleIndices) * src->indexCount);
            memcpy(dest->indexData, src->indexData, sizeof(TriangleIndices) * src->indexCount);
            dest->indexCount = src->indexCount;
        }
    }
}

void combineGeometryData(GeometryData *dest, GeometryData *src) {
    int destPreCombineVertexCount = dest->vertexCount;

    if (src->vertexCount > 0) {
        if (dest->vertexCount > 0) {
            int totalCount = src->vertexCount + dest->vertexCount;
            dest->vertexData = realloc(dest->vertexData, totalCount * sizeof(Vertex));
            memcpy(dest->vertexData + dest->vertexCount, src->vertexData,
                   src->vertexCount * sizeof(Vertex));
            dest->vertexCount += src->vertexCount;
        } else {
            dest->vertexData = (Vertex *)malloc(src->vertexCount * sizeof(Vertex));
            memcpy(dest->vertexData, src->vertexData, src->vertexCount * sizeof(Vertex));
            dest->vertexCount = src->vertexCount;
        }
    }

    combineIndexGeometryData(dest, src, destPreCombineVertexCount);
}

void combineAndOffsetGeometryData(GeometryData *dest, GeometryData *src, simd_float3 offset) {
    int destPreCombineVertexCount = dest->vertexCount;

    if (src->vertexCount > 0) {
        if (dest->vertexCount > 0) {
            int totalCount = src->vertexCount + dest->vertexCount;
            dest->vertexData = realloc(dest->vertexData, totalCount * sizeof(Vertex));
            memcpy(dest->vertexData + dest->vertexCount, src->vertexData,
                   src->vertexCount * sizeof(Vertex));
            for (int i = dest->vertexCount; i < totalCount; i++) {
                dest->vertexData[i].position += simd_make_float4(offset.x, offset.y, offset.z, 0.0);
            }
            dest->vertexCount += src->vertexCount;
        } else {
            dest->vertexData = (Vertex *)malloc(src->vertexCount * sizeof(Vertex));
            memcpy(dest->vertexData, src->vertexData, src->vertexCount * sizeof(Vertex));
            for (int i = 0; i < src->vertexCount; i++) {
                dest->vertexData[i].position += simd_make_float4(offset.x, offset.y, offset.z, 0.0);
            }
            dest->vertexCount = src->vertexCount;
        }
    }

    combineIndexGeometryData(dest, src, destPreCombineVertexCount);
}

void combineAndScaleGeometryData(GeometryData *dest, GeometryData *src, simd_float3 scale) {
    int destPreCombineVertexCount = dest->vertexCount;

    if (src->vertexCount > 0) {
        if (dest->vertexCount > 0) {
            int totalCount = src->vertexCount + dest->vertexCount;
            dest->vertexData = realloc(dest->vertexData, totalCount * sizeof(Vertex));
            memcpy(dest->vertexData + dest->vertexCount, src->vertexData,
                   src->vertexCount * sizeof(Vertex));
            for (int i = dest->vertexCount; i < totalCount; i++) {
                dest->vertexData[i].position *= simd_make_float4(scale.x, scale.y, scale.z, 1.0);
            }
            dest->vertexCount += src->vertexCount;
        } else {
            dest->vertexData = (Vertex *)malloc(src->vertexCount * sizeof(Vertex));
            memcpy(dest->vertexData, src->vertexData, src->vertexCount * sizeof(Vertex));
            for (int i = 0; i < src->vertexCount; i++) {
                dest->vertexData[i].position *= simd_make_float4(scale.x, scale.y, scale.z, 1.0);
            }
            dest->vertexCount = src->vertexCount;
        }
    }

    combineIndexGeometryData(dest, src, destPreCombineVertexCount);
}

void combineAndScaleAndOffsetGeometryData(GeometryData *dest, GeometryData *src, simd_float3 scale,
                                          simd_float3 offset) {
    int destPreCombineVertexCount = dest->vertexCount;

    if (src->vertexCount > 0) {
        if (dest->vertexCount > 0) {
            int totalCount = src->vertexCount + dest->vertexCount;
            dest->vertexData = realloc(dest->vertexData, totalCount * sizeof(Vertex));
            memcpy(dest->vertexData + dest->vertexCount, src->vertexData,
                   src->vertexCount * sizeof(Vertex));
            for (int i = dest->vertexCount; i < totalCount; i++) {
                dest->vertexData[i].position *= simd_make_float4(scale.x, scale.y, scale.z, 1.0);
                dest->vertexData[i].position += simd_make_float4(offset.x, offset.y, offset.z, 0.0);
            }
            dest->vertexCount += src->vertexCount;
        } else {
            dest->vertexData = (Vertex *)malloc(src->vertexCount * sizeof(Vertex));
            memcpy(dest->vertexData, src->vertexData, src->vertexCount * sizeof(Vertex));
            for (int i = 0; i < src->vertexCount; i++) {
                dest->vertexData[i].position *= simd_make_float4(scale.x, scale.y, scale.z, 1.0);
                dest->vertexData[i].position += simd_make_float4(offset.x, offset.y, offset.z, 0.0);
            }
            dest->vertexCount = src->vertexCount;
        }
    }

    combineIndexGeometryData(dest, src, destPreCombineVertexCount);
}

void combineAndTransformGeometryData(GeometryData *dest, GeometryData *src,
                                     simd_float4x4 transform) {
    int destPreCombineVertexCount = dest->vertexCount;
    simd_float4x4 rotation = simd_transpose(simd_inverse(transform));
    simd_float3x3 rot =
        simd_matrix(simd_make_float3(rotation.columns[0]), simd_make_float3(rotation.columns[1]),
                    simd_make_float3(rotation.columns[2]));

    if (src->vertexCount > 0) {
        if (dest->vertexCount > 0) {
            int totalCount = src->vertexCount + dest->vertexCount;
            dest->vertexData = realloc(dest->vertexData, totalCount * sizeof(Vertex));
            memcpy(dest->vertexData + dest->vertexCount, src->vertexData,
                   src->vertexCount * sizeof(Vertex));
            for (int i = dest->vertexCount; i < totalCount; i++) {
                dest->vertexData[i].position = simd_mul(transform, dest->vertexData[i].position);
                dest->vertexData[i].normal = simd_mul(rot, dest->vertexData[i].normal);
            }
            dest->vertexCount += src->vertexCount;
        } else {
            dest->vertexData = (Vertex *)malloc(src->vertexCount * sizeof(Vertex));
            memcpy(dest->vertexData, src->vertexData, src->vertexCount * sizeof(Vertex));
            for (int i = 0; i < src->vertexCount; i++) {
                dest->vertexData[i].position = simd_mul(transform, dest->vertexData[i].position);
                dest->vertexData[i].normal = simd_mul(rot, dest->vertexData[i].normal);
            }
            dest->vertexCount = src->vertexCount;
        }
    }

    combineIndexGeometryData(dest, src, destPreCombineVertexCount);
}

void copyGeometryVertexData(GeometryData *dest, GeometryData *src, int start, int count) {
    if (src->vertexCount > 0) {
        dest->vertexCount = count;
        dest->vertexData = (Vertex *)malloc(count * sizeof(Vertex));
        memcpy(dest->vertexData, src->vertexData + start, count * sizeof(Vertex));
    }
}

void copyGeometryIndexData(GeometryData *dest, GeometryData *src, int start, int count) {
    if (src->indexCount > 0) {
        dest->indexCount = count;
        dest->indexData = (TriangleIndices *)malloc(sizeof(TriangleIndices) * count);
        memcpy(dest->indexData, src->indexData + start, count * sizeof(TriangleIndices));
    }
}

void copyGeometryData(GeometryData *dest, GeometryData *src) {

    copyGeometryVertexData(dest, src, 0, src->vertexCount);
    copyGeometryIndexData(dest, src, 0, src->indexCount);
}

void computeNormalsOfGeometryData(GeometryData *data) {
    if (data->indexCount > 0) {
        int count = data->indexCount;
        for (int i = 0; i < count; i++) {
            uint32_t i0 = data->indexData[i].i0;
            uint32_t i1 = data->indexData[i].i1;
            uint32_t i2 = data->indexData[i].i2;
            
            Vertex *v0 = &data->vertexData[i0];
            Vertex *v1 = &data->vertexData[i1];
            Vertex *v2 = &data->vertexData[i2];

            simd_float3 p0 = simd_make_float3(v0->position);
            simd_float3 p1 = simd_make_float3(v1->position);
            simd_float3 p2 = simd_make_float3(v2->position);

            simd_float3 normal = simd_cross(p1 - p0, p2 - p0);
            if (simd_length(normal) > 0) {
                v0->normal += normal;
                v1->normal += normal;
                v2->normal += normal;
            }
            //            }
        }

        count = data->vertexCount;
        for (int i = 0; i < count; i++) {
            Vertex *v = &data->vertexData[i];
            v->normal = simd_normalize(v->normal);
        }

    } else {
        int count = data->vertexCount;
        for (int i = 0; i < count; i += 3) {
            Vertex *v0 = &data->vertexData[i];
            Vertex *v1 = &data->vertexData[i + 1];
            Vertex *v2 = &data->vertexData[i + 2];

            simd_float3 p0 = simd_make_float3(v0->position);
            simd_float3 p1 = simd_make_float3(v1->position);
            simd_float3 p2 = simd_make_float3(v2->position);

            simd_float3 normal = simd_normalize(simd_cross(p1 - p0, p2 - p0));

            v0->normal = normal;
            v1->normal = normal;
            v2->normal = normal;
        }
    }
}

void reverseFacesOfGeometryData(GeometryData *data) {
    int indexCount = data->indexCount;
    if (indexCount > 0) {
        for (int i = 0; i < indexCount; i++) {
            uint32_t i1 = data->indexData[i].i1;
            uint32_t i2 = data->indexData[i].i2;
            data->indexData[i].i1 = i2;
            data->indexData[i].i2 = i1;
        }
    }

    int vertexCount = data->vertexCount;
    if (vertexCount > 0) {
        for (int i = 0; i < vertexCount; i++) {
            data->vertexData[i].normal *= -1.0;
        }
    }
}

void transformGeometryData(GeometryData *data, simd_float4x4 transform) {
    simd_float4x4 rotation = simd_transpose(simd_inverse(transform));
    simd_float3x3 rot =
        simd_matrix(simd_make_float3(rotation.columns[0]), simd_make_float3(rotation.columns[1]),
                    simd_make_float3(rotation.columns[2]));
    int count = data->vertexCount;
    for (int i = 0; i < count; i++) {
        data->vertexData[i].position = simd_mul(transform, data->vertexData[i].position);
        data->vertexData[i].normal = simd_mul(rot, data->vertexData[i].normal);
    }
}

void deindexGeometryData(GeometryData *dest, GeometryData *src) {
    int triangleCount = src->indexCount;
    int newVertexCount = triangleCount * 3;
    Vertex *vertices = (Vertex *)malloc(newVertexCount * sizeof(Vertex));

    int vertexIndex = 0;
    for (int i = 0; i < triangleCount; i++) {
        TriangleIndices t = src->indexData[i];
        Vertex v0 = src->vertexData[t.i0];
        Vertex v1 = src->vertexData[t.i1];
        Vertex v2 = src->vertexData[t.i2];

        vertices[vertexIndex].position = v0.position;
        vertices[vertexIndex].normal = v0.normal;
        vertices[vertexIndex].uv = v0.uv;

        vertexIndex += 1;

        vertices[vertexIndex].position = v1.position;
        vertices[vertexIndex].normal = v1.normal;
        vertices[vertexIndex].uv = v1.uv;

        vertexIndex += 1;

        vertices[vertexIndex].position = v2.position;
        vertices[vertexIndex].normal = v2.normal;
        vertices[vertexIndex].uv = v2.uv;

        vertexIndex += 1;
    }

    dest->indexCount = 0;
    dest->indexData = NULL;
    dest->vertexCount = vertexIndex;
    dest->vertexData = vertices;
}

void unrollGeometryData(GeometryData *dest, GeometryData *src) {
    int triangleCount = src->indexCount;
    int newVertexCount = triangleCount * 3;
    Vertex *vertices = (Vertex *)malloc(newVertexCount * sizeof(Vertex));
    TriangleIndices *triangles = (TriangleIndices *)malloc(sizeof(TriangleIndices) * triangleCount);

    int vertexIndex = 0;
    simd_float3 p01, p02, p0, p1, p2;
    simd_float3 normal;
    for (int i = 0; i < triangleCount; i++) {
        TriangleIndices t = src->indexData[i];

        Vertex v0 = src->vertexData[t.i0];
        Vertex v1 = src->vertexData[t.i1];
        Vertex v2 = src->vertexData[t.i2];

        p0 = simd_make_float3(v0.position);
        p1 = simd_make_float3(v1.position);
        p2 = simd_make_float3(v2.position);

        p01 = p1 - p0;
        p02 = p2 - p0;

        normal = simd_normalize(simd_cross(p01, p02));

        vertices[vertexIndex].position = v0.position;
        vertices[vertexIndex].normal = normal;
        vertices[vertexIndex].uv = v0.uv;

        triangles[i].i0 = vertexIndex;

        vertexIndex += 1;

        vertices[vertexIndex].position = v1.position;
        vertices[vertexIndex].normal = normal;
        vertices[vertexIndex].uv = v1.uv;

        triangles[i].i1 = vertexIndex;

        vertexIndex += 1;

        vertices[vertexIndex].position = v2.position;
        vertices[vertexIndex].normal = normal;
        vertices[vertexIndex].uv = v2.uv;

        triangles[i].i2 = vertexIndex;

        vertexIndex += 1;
    }

    dest->indexCount = triangleCount;
    dest->indexData = triangles;
    dest->vertexCount = vertexIndex;
    dest->vertexData = vertices;
}
