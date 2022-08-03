//
//  Bounds.c
//  Pods
//
//  Created by Reza Ali on 11/30/20.
//
#include <stdio.h>
#include <simd/simd.h>

#include "Bounds.h"

Bounds computeBoundsFromVertices(const Vertex *vertices, int count) {
    if (count > 0) {
        simd_float3 min = {INFINITY, INFINITY, INFINITY};
        simd_float3 max = {-INFINITY, -INFINITY, -INFINITY};
        for (int i = 0; i < count; i++) {
            simd_float3 pos = vertices[i].position.xyz;

            min = simd_min(pos, min);
            max = simd_max(pos, max);
        }
        return (Bounds) { .min = min, .max = max };
    }
    return (Bounds) { .min = {0.0, 0.0, 0.0},
                      .max = {0.0, 0.0, 0.0} };
}

Bounds computeBoundsFromVerticesAndTransform(const Vertex *vertices, int count, simd_float4x4 transform) {
    if (count > 0) {
        simd_float3 min = {INFINITY, INFINITY, INFINITY};
        simd_float3 max = {-INFINITY, -INFINITY, -INFINITY};
        for (int i = 0; i < count; i++) {
            simd_float3 pos = simd_mul(transform, vertices[i].position).xyz;

            min = simd_min(pos, min);
            max = simd_max(pos, max);
        }
        return (Bounds) { .min = min, .max = max };
    }
    return (Bounds) { .min = {0.0, 0.0, 0.0},
                      .max = {0.0, 0.0, 0.0} };
}

Bounds mergeBounds(Bounds a, Bounds b) {
    simd_float3 amin = simd_min(a.min, a.max);
    simd_float3 amax = simd_max(a.min, a.max);

    simd_float3 bmin = simd_min(b.min, b.max);
    simd_float3 bmax = simd_max(b.min, b.max);

    simd_float3 min = simd_min(amin, bmin);
    simd_float3 max = simd_max(amax, bmax);

    return (Bounds) { .min = min, .max = max };
}

Bounds expandBounds(Bounds bounds, simd_float3 pt) {
    bounds.min = simd_min(bounds.min, pt);
    bounds.max = simd_max(bounds.max, pt);
    return bounds;
}

static simd_float4 corner(Bounds a, int index) {
    return simd_make_float4(index & 1 ? a.min.x : a.max.x,
                            index & 2 ? a.min.y : a.max.y,
                            index & 4 ? a.min.z : a.max.z,
                            1.0);
}

Bounds transformBounds(Bounds a, simd_float4x4 transform) {

    simd_float3 min = {INFINITY, INFINITY, INFINITY};
    simd_float3 max = {-INFINITY, -INFINITY, -INFINITY};

    for(int i=0;i<8;++i) {
        simd_float3 v = simd_mul(transform, corner(a, i)).xyz;
        min = simd_min(min, v);
        max = simd_max(max, v);
    }

    return (Bounds) { .min = min, .max = max };
}
