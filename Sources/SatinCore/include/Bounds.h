//
//  Bounds.h
//  Satin
//
//  Created by Reza Ali on 11/30/20.
//

#ifndef Bounds_h
#define Bounds_h

#include "Types.h"

Bounds createBounds(void);

Bounds computeBoundsFromVertices(const Vertex *vertices, int count);
Bounds computeBoundsFromVerticesAndTransform(const Vertex *vertices, int count,
                                             simd_float4x4 transform);

Bounds expandBounds(Bounds bounds, simd_float3 pt);
Bounds mergeBounds(Bounds a, Bounds b);
Bounds transformBounds(Bounds a, simd_float4x4 transform);

static simd_float4 boundsCorner(Bounds a, int index) {
    return simd_make_float4(index & 1 ? a.min.x : a.max.x, index & 2 ? a.min.y : a.max.y,
                            index & 4 ? a.min.z : a.max.z, 1.0);
}

void mergeBoundsInPlace(Bounds *a, const Bounds *b);
void expandBoundsInPlace(Bounds *bounds, const simd_float3 *pt);

#endif /* Bounds_h */
