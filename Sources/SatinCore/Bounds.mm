//
//  Bounds.c
//  Satin
//
//  Created by Reza Ali on 11/30/20.
//
#include <stdio.h>
#include <simd/simd.h>

#include "Bounds.h"

Bounds createBounds(void)
{
    return (Bounds) { .min = { INFINITY, INFINITY, INFINITY },
                      .max = { -INFINITY, -INFINITY, -INFINITY } };
}

Bounds computeBoundsFromVertices(const Vertex *vertices, int count)
{
    if (count > 0) {
        Bounds result = createBounds();
        for (int i = 0; i < count; i++) {
            result = expandBounds(result, vertices[i].position.xyz);
        }
        return result;
    }
    return createBounds();
}

Bounds computeBoundsFromVerticesAndTransform(const Vertex *vertices, int count,
                                             simd_float4x4 transform)
{
    if (count > 0) {
        Bounds result = createBounds();
        for (int i = 0; i < count; i++) {
            result = expandBounds(result, simd_mul(transform, vertices[i].position).xyz);
        }
        return result;
    }
    return createBounds();
}

Bounds mergeBounds(Bounds a, Bounds b)
{
    simd_float3 min = a.min, max = a.max;
    for (int i = 0; i < 3; i++) {
        if (b.min[i] != INFINITY) { min[i] = simd_min(a.min[i], b.min[i]); }
        if (b.max[i] != -INFINITY) { max[i] = simd_max(a.max[i], b.max[i]); }
    }
    return (Bounds) { .min = min, .max = max };
}

Bounds expandBounds(Bounds bounds, simd_float3 pt)
{
    return (Bounds) { .min = simd_min(bounds.min, pt), .max = simd_max(bounds.max, pt) };
}

Bounds transformBounds(Bounds a, simd_float4x4 transform)
{
    Bounds result = createBounds();
    for (int i = 0; i < 8; ++i) {
        result = expandBounds(result, simd_mul(transform, boundsCorner(a, i)).xyz);
    }
    return result;
}

simd_float4 boundsCorner(Bounds a, int index)
{
    return simd_make_float4(index & 1 ? a.min.x : a.max.x, index & 2 ? a.min.y : a.max.y,
                            index & 4 ? a.min.z : a.max.z, 1.0);
}

void mergeBoundsInPlace(Bounds *a, const Bounds *b)
{
    for (int i = 0; i < 3; i++) {
        if (b->min[i] != INFINITY) { a->min[i] = simd_min(a->min[i], b->min[i]); }
        if (b->max[i] != -INFINITY) { a->max[i] = simd_max(a->max[i], b->max[i]); }
    }
}

void expandBoundsInPlace(Bounds *bounds, const simd_float3 *pt)
{
    bounds->min = simd_min(bounds->min, *pt);
    bounds->max = simd_max(bounds->max, *pt);
}
