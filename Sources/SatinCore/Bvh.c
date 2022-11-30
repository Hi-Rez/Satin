//
//  Bvh.c
//
//
//  Created by Reza Ali on 11/27/22.
//

#include "Bvh.h"
#include "Bounds.h"
#include <malloc/_malloc.h>
#include <simd/simd.h>
#include <stdio.h>

// BVH Implementation is based on:
// https://jacco.ompf2.com/2022/04/13/how-to-build-a-bvh-part-1-basics/

bool isLeaf(BVHNode node) { return node.triCount > 0; }

void updateBVHNodeBounds(BVH *bvh, uint nodeIndex) {
    BVHNode *node = &bvh->nodes[nodeIndex];
    node->aabb = createBounds();

    const bool hasTriangles = bvh->geometry.indexCount > 0;

    for (uint first = node->leftFirst, i = 0; i < node->triCount; i++) {
        const uint triIdx = bvh->triIDs[first + i];
        const TriangleIndices tri = hasTriangles
                                        ? bvh->geometry.indexData[triIdx]
                                        : (TriangleIndices) { triIdx, triIdx + 1, triIdx + 2 };

        const simd_float3 p0 = simd_make_float3(bvh->geometry.vertexData[tri.i0].position);
        const simd_float3 p1 = simd_make_float3(bvh->geometry.vertexData[tri.i1].position);
        const simd_float3 p2 = simd_make_float3(bvh->geometry.vertexData[tri.i2].position);

        node->aabb.min = simd_min(node->aabb.min, p0);
        node->aabb.min = simd_min(node->aabb.min, p1);
        node->aabb.min = simd_min(node->aabb.min, p2);

        node->aabb.max = simd_max(node->aabb.max, p0);
        node->aabb.max = simd_max(node->aabb.max, p1);
        node->aabb.max = simd_max(node->aabb.max, p2);
    }
}

void subdivideBVHNode(BVH *bvh, uint nodeIndex) {
    BVHNode *node = &bvh->nodes[nodeIndex];

    if (node->triCount <= 2) return;

    const simd_float3 extent = node->aabb.max - node->aabb.min;

    int axis = 0;
    if (extent.y > extent.x) axis = 1;
    if (extent.z > extent[axis]) axis = 2;
    const float splitPos = node->aabb.min[axis] + extent[axis] * 0.5;

    int start = node->leftFirst;
    int end = start + node->triCount - 1;
    while (start <= end) {
        if (bvh->centroids[bvh->triIDs[start]][axis] < splitPos) {
            start++;
        } else {
            const uint first = bvh->triIDs[start];
            const uint last = bvh->triIDs[end];
            bvh->triIDs[end] = first;
            bvh->triIDs[start] = last;
            end--;
        }
    }

    int leftCount = start - node->leftFirst;
    if (leftCount == 0 || leftCount == node->triCount) return;

    const int leftNodeIndex = bvh->nodesUsed++;
    const int rightNodeIndex = bvh->nodesUsed++;

    bvh->nodes[leftNodeIndex].leftFirst = node->leftFirst;
    bvh->nodes[leftNodeIndex].triCount = leftCount;

    bvh->nodes[rightNodeIndex].leftFirst = start;
    bvh->nodes[rightNodeIndex].triCount = node->triCount - leftCount;

    node->leftFirst = leftNodeIndex;
    node->triCount = 0;

    updateBVHNodeBounds(bvh, leftNodeIndex);
    updateBVHNodeBounds(bvh, rightNodeIndex);

    subdivideBVHNode(bvh, leftNodeIndex);
    subdivideBVHNode(bvh, rightNodeIndex);
}

BVH createBVH(GeometryData geometry) {
    const bool hasTriangles = geometry.indexCount > 0;
    uint N = hasTriangles ? geometry.indexCount : (geometry.vertexCount / 3);

    BVHNode *nodes = (BVHNode *)malloc(sizeof(BVHNode) * N * 2 - 1);
    simd_float3 *centroids = (simd_float3 *)malloc(sizeof(simd_float3) * N);
    uint *triIDs = (uint *)malloc(sizeof(uint) * N);
    
    for (uint i = 0; i < N; i++) {
        triIDs[i] = i;
        const TriangleIndices tri = hasTriangles
                                        ? geometry.indexData[i]
                                        : (TriangleIndices) { i * 3, i * 3 + 1, i * 3 + 2 };
        const simd_float3 p0 = simd_make_float3(geometry.vertexData[tri.i0].position);
        const simd_float3 p1 = simd_make_float3(geometry.vertexData[tri.i1].position);
        const simd_float3 p2 = simd_make_float3(geometry.vertexData[tri.i2].position);
        centroids[i] = (p0 + p1 + p2) / 3.0;
    }

    BVH bvh = (BVH) { .geometry = geometry,
                      .nodes = nodes,
                      .centroids = centroids,
                      .triIDs = triIDs,
                      .nodesUsed = 0 };

    if (N > 0) {
        bvh.nodesUsed++;
        BVHNode *root = &nodes[0];
        root->leftFirst = 0;
        root->triCount = N;

        updateBVHNodeBounds(&bvh, 0);
        subdivideBVHNode(&bvh, 0);
    }

    return bvh;
}

void freeBVH(BVH bvh) {
    free(bvh.triIDs);
    free(bvh.nodes);
    free(bvh.centroids);
}
