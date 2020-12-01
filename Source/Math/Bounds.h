//
//  Bounds.h
//  Pods
//
//  Created by Reza Ali on 11/30/20.
//

#ifndef Bounds_h
#define Bounds_h

#include "Types.h"

Bounds computeBoundsFromVertices(Vertex *vertices, int count);

Bounds mergeBounds(Bounds a, Bounds b);
Bounds transformBounds(Bounds a, simd_float4x4 transform);

#endif /* Bounds_h */
