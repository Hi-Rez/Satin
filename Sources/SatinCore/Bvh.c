//
//  Bvh.c
//
//
//  Created by Reza Ali on 11/27/22.
//

#include "Bvh.h"
#include "Bounds.h"
#include <float.h>
#include <malloc/_malloc.h>
#include <simd/simd.h>
#include <stdio.h>

// BVH Implementation is based on:
// https://jacco.ompf2.com/2022/04/13/how-to-build-a-bvh-part-1-basics/

typedef struct {
    Bounds aabb;
    int triCount;
} Bin;

Bin createBin() { return (Bin) { .aabb = createBounds(), .triCount = 0 }; }

bool isLeaf(BVHNode node) { return node.triCount > 0; }

float surfaceAreaBounds(Bounds *b) {
    for (int i = 0; i < 3; i++) {
        if (b->min[i] == INFINITY || b->max[i] == -INFINITY) { return 0.0; }
    }

    const simd_float3 extents = b->max - b->min;
    return extents.x * extents.y + extents.y * extents.z + extents.z * extents.x;
}

float calculateNodeCost(BVHNode *node) { return node->triCount * surfaceAreaBounds(&node->aabb); }

#define BINS 8
#define BINSMINUSONE BINS - 1
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

float findBestSplitPlane(BVH *bvh, BVHNode *node, int *axis, float *splitPos) {
    // split along longest axis to optimize generation speed
    const simd_float3 extent = node->aabb.max - node->aabb.min;
    int a = 0;
    if (extent.y > extent.x) a = 1;
    if (extent.z > extent[a]) a = 2;
    *axis = a;

    float bestCost = FLT_MAX;
    float boundsMin = INFINITY, boundsMax = -INFINITY;
    for (int i = 0; i < node->triCount; i++) {
        const uint triID = bvh->triIDs[node->leftFirst + i];
        const float center = bvh->centroids[triID][a];
        boundsMin = simd_min(boundsMin, center);
        boundsMax = simd_max(boundsMax, center);
    }

    // populate the bins
    Bin bin[BINS] = { createBin(), createBin(), createBin(), createBin(),
                      createBin(), createBin(), createBin(), createBin() };

    float scale = (float)BINS / (boundsMax - boundsMin);
    for (uint i = 0; i < node->triCount; i++) {
        const uint triID = bvh->triIDs[node->leftFirst + i];
        const TriangleIndices tri = bvh->triangles[triID];
        const int binID = MIN((bvh->centroids[triID][a] - boundsMin) * scale, BINSMINUSONE);

        bin[binID].triCount++;

        expandBoundsInPlace(&bin[binID].aabb, &bvh->positions[tri.i0]);
        expandBoundsInPlace(&bin[binID].aabb, &bvh->positions[tri.i1]);
        expandBoundsInPlace(&bin[binID].aabb, &bvh->positions[tri.i2]);
    }

    // gather data for the 7 planes between the 8 bins
    float leftArea[BINSMINUSONE], rightArea[BINSMINUSONE];
    int leftCount[BINSMINUSONE], rightCount[BINSMINUSONE];
    Bounds leftBox = createBounds(), rightBox = createBounds();

    int leftSum = 0, rightSum = 0;
    for (int i = 0; i < BINSMINUSONE; i++) {
        leftSum += bin[i].triCount;
        leftCount[i] = leftSum;
        mergeBoundsInPlace(&leftBox, &bin[i].aabb);
        leftArea[i] = surfaceAreaBounds(&leftBox);

        rightSum += bin[BINSMINUSONE - i].triCount;
        rightCount[BINSMINUSONE - 1 - i] = rightSum;
        mergeBoundsInPlace(&rightBox, &bin[BINSMINUSONE - i].aabb);
        rightArea[BINSMINUSONE - 1 - i] = surfaceAreaBounds(&rightBox);
    }

    // calculate SAH cost for the 7 planes
    scale = (boundsMax - boundsMin) / (float)BINS;
    for (int i = 0; i < BINSMINUSONE; i++) {
        const float planeCost = leftCount[i] * leftArea[i] + rightCount[i] * rightArea[i];
        if (planeCost < bestCost) {
            *splitPos = boundsMin + scale * (i + 1);
            bestCost = planeCost;
        }
    }
    return bestCost;
}

void updateBVHNodeBounds(BVH *bvh, uint nodeIndex) {
    BVHNode *node = &bvh->nodes[nodeIndex];
    node->aabb = createBounds();

    for (uint first = node->leftFirst, i = 0; i < node->triCount; i++) {
        const uint triID = bvh->triIDs[first + i];
        const TriangleIndices tri = bvh->triangles[triID];
        expandBoundsInPlace(&node->aabb, &bvh->positions[tri.i0]);
        expandBoundsInPlace(&node->aabb, &bvh->positions[tri.i1]);
        expandBoundsInPlace(&node->aabb, &bvh->positions[tri.i2]);
    }
}

void subdivideBVHNode(BVH *bvh, uint nodeIndex) {
    BVHNode *node = &bvh->nodes[nodeIndex];

    int axis = 0;
    float splitPos;

    if (bvh->useSAH) {
        // Surface Area Heuristic
        const float splitCost = findBestSplitPlane(bvh, node, &axis, &splitPos);
        const float noSplitCost = calculateNodeCost(node);
        if (splitCost >= noSplitCost) return;
    } else {
        // Midpoint Split
        if (node->triCount <= 2) return;
        const simd_float3 extent = node->aabb.max - node->aabb.min;
        if (extent.y > extent.x) axis = 1;
        if (extent.z > extent[axis]) axis = 2;
        splitPos = node->aabb.min[axis] + extent[axis] * 0.5;
    }

    int start = node->leftFirst;
    int end = start + node->triCount - 1;
    while (start <= end) {
        const uint triID = bvh->triIDs[start];
        if (bvh->centroids[triID][axis] < splitPos) {
            start++;
        } else {
            const uint first = bvh->triIDs[start];
            bvh->triIDs[start] = bvh->triIDs[end];
            bvh->triIDs[end] = first;
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

BVH createBVH(GeometryData geometry, bool useSAH) {
    const bool hasTriangles = geometry.indexCount > 0;
    const uint N = hasTriangles ? geometry.indexCount : (geometry.vertexCount / 3);

    BVHNode *nodes = (BVHNode *)malloc(sizeof(BVHNode) * N * 2 - 1);
    simd_float3 *centroids = (simd_float3 *)malloc(sizeof(simd_float3) * N);
    simd_float3 *positions = (simd_float3 *)malloc(sizeof(simd_float3) * geometry.vertexCount);
    uint *triIDs = (uint *)malloc(sizeof(uint) * N);
    TriangleIndices *triangles = (TriangleIndices *)malloc(sizeof(TriangleIndices) * N);
    Bounds aabb = createBounds();

    if (hasTriangles) {
        for (uint i = 0; i < N; i++) {
            triIDs[i] = i;
            const TriangleIndices tri = geometry.indexData[i];
            triangles[i] = tri;

            positions[tri.i0] = geometry.vertexData[tri.i0].position.xyz;
            positions[tri.i1] = geometry.vertexData[tri.i1].position.xyz;
            positions[tri.i2] = geometry.vertexData[tri.i2].position.xyz;

            expandBoundsInPlace(&aabb, &positions[tri.i0]);
            expandBoundsInPlace(&aabb, &positions[tri.i1]);
            expandBoundsInPlace(&aabb, &positions[tri.i2]);

            centroids[i] = (positions[tri.i0] + positions[tri.i1] + positions[tri.i2]) / 3.0;
        }
    } else {
        for (uint i = 0; i < N; i++) {
            triIDs[i] = i;
            const TriangleIndices tri = (TriangleIndices) { i * 3, i * 3 + 1, i * 3 + 2 };
            triangles[i] = tri;

            positions[tri.i0] = geometry.vertexData[tri.i0].position.xyz;
            positions[tri.i1] = geometry.vertexData[tri.i1].position.xyz;
            positions[tri.i2] = geometry.vertexData[tri.i2].position.xyz;

            expandBoundsInPlace(&aabb, &positions[tri.i0]);
            expandBoundsInPlace(&aabb, &positions[tri.i1]);
            expandBoundsInPlace(&aabb, &positions[tri.i2]);

            centroids[i] = (positions[tri.i0] + positions[tri.i1] + positions[tri.i2]) / 3.0;
        }
    }

    BVH bvh = (BVH) { .geometry = geometry,
                      .nodes = nodes,
                      .centroids = centroids,
                      .positions = positions,
                      .triangles = triangles,
                      .triIDs = triIDs,
                      .nodesUsed = 0,
                      .useSAH = useSAH };

    if (N > 0) {
        bvh.nodesUsed++;
        BVHNode *root = &nodes[0];
        root->leftFirst = 0;
        root->triCount = N;
        root->aabb = aabb;
        subdivideBVHNode(&bvh, 0);
    }

    return bvh;
}

void freeBVH(BVH bvh) {
    free(bvh.triIDs);
    free(bvh.nodes);
    free(bvh.centroids);
    free(bvh.positions);
    free(bvh.triangles);
}
