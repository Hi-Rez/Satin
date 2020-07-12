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

void freeGeometryData(GeometryData *data) {
    if (data->vertexCount > 0 && data->vertexData == NULL) { return; }
    free(data->vertexData);

    if (data->indexCount > 0 && data->indexData == NULL) { return; }
    free(data->indexData);
}


void combineGeometryData( GeometryData *dest, GeometryData *src, simd_float3 offset )
{
    int destPreCombineVertexCount = dest->vertexCount;
    
    if (src->vertexCount > 0) {
        if (dest->vertexCount > 0) {
            int totalCount = src->vertexCount + dest->vertexCount;
            dest->vertexData = realloc(dest->vertexData, totalCount * sizeof(Vertex));
            memcpy(dest->vertexData + dest->vertexCount, src->vertexData, src->vertexCount * sizeof(Vertex));
            if(greaterThanZero(simd_length(offset))) {
                for(int i = dest->vertexCount; i < totalCount; i++) {
                    dest->vertexData[i].position += simd_make_float4(offset.x, offset.y, offset.z, 0.0);
                }
            }
            dest->vertexCount += src->vertexCount;
        } else {
            dest->vertexData = (Vertex *)malloc(src->vertexCount * sizeof(Vertex));
            memcpy(dest->vertexData, src->vertexData, src->vertexCount * sizeof(Vertex));
            if(greaterThanZero(simd_length(offset))) {
                for(int i = 0; i < src->vertexCount; i++) {
                    dest->vertexData[i].position += simd_make_float4(offset.x, offset.y, offset.z, 0.0);
                }
            }
            dest->vertexCount = src->vertexCount;
        }
    }
    
    if(src->indexCount > 0) {
        if(dest->indexCount > 0) {
            int totalCount = src->indexCount + dest->indexCount;
            dest->indexData = realloc(dest->indexData, totalCount * sizeof(TriangleIndices));
            memcpy(dest->indexData + dest->indexCount, src->indexData, src->indexCount * sizeof(TriangleIndices));
            if(destPreCombineVertexCount > 0) {
                for(int i = dest->indexCount; i < totalCount; i++) {
                    dest->indexData[i].i0 += destPreCombineVertexCount;
                    dest->indexData[i].i1 += destPreCombineVertexCount;
                    dest->indexData[i].i2 += destPreCombineVertexCount;
                }
            }
            dest->indexCount += src->indexCount;
        }
        else {
            dest->indexData = (TriangleIndices *)malloc(sizeof(TriangleIndices) * src->indexCount);
            memcpy(dest->indexData, src->indexData, sizeof(TriangleIndices) * src->indexCount);
            dest->indexCount = src->indexCount;
        }
    }
}
