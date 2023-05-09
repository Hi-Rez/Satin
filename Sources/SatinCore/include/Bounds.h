//
//  Bounds.h
//  Satin
//
//  Created by Reza Ali on 11/30/20.
//

#ifndef Bounds_h
#define Bounds_h

#include "Types.h"

#if defined(__cplusplus)
extern "C" {
#endif

Bounds createBounds(void);

Bounds computeBoundsFromVertices(const Vertex *vertices, int count);
Bounds computeBoundsFromVerticesAndTransform(const Vertex *vertices, int count,
                                             simd_float4x4 transform);

Bounds expandBounds(Bounds bounds, simd_float3 pt);
Bounds mergeBounds(Bounds a, Bounds b);
Bounds transformBounds(Bounds a, simd_float4x4 transform);

simd_float4 boundsCorner(Bounds a, int index);

void mergeBoundsInPlace(Bounds *a, const Bounds *b);
void expandBoundsInPlace(Bounds *bounds, const simd_float3 *pt);

#if defined(__cplusplus)
}
#endif

#endif /* Bounds_h */
