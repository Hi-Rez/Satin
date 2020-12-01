//
//  Bounds.c
//  Pods
//
//  Created by Reza Ali on 11/30/20.
//
#include <stdio.h>
#include <simd/simd.h>

#include "Bounds.h"

Bounds computeBoundsFromVertices(Vertex *vertices, int count)
{
    printf("computeBoundsFromVertices");
    if(count > 0) {
        simd_float3 min = simd_make_float3(INFINITY, INFINITY, INFINITY);
        simd_float3 max = simd_make_float3(-INFINITY, -INFINITY, -INFINITY);
        printf("vertex count: %i\n", count);
        
        for (int i = 0; i < count; i++) {
            
            Vertex *vertex = &vertices[i];
            simd_float4 pos = vertex->position;
            
            printf("pos: %f, %f, %f\n", pos.x, pos.y, pos.z);
            
            min.x = simd_min(pos.x, min.x);
            min.y = simd_min(pos.y, min.y);
            min.z = simd_min(pos.z, min.z);
            
            max.x = simd_max(pos.x, max.x);
            max.y = simd_max(pos.y, max.y);
            max.z = simd_max(pos.z, max.z);
        }
        
        return (Bounds) { .min = min, .max = max };
    }
    return (Bounds) { .min = simd_make_float3(0.0, 0.0, 0.0), .max = simd_make_float3(0.0, 0.0, 0.0)};
}

Bounds mergeBounds(Bounds a, Bounds b)
{
    simd_float3 amin = simd_min(a.min, a.max);
    simd_float3 amax = simd_max(a.min, a.max);
    
    simd_float3 bmin = simd_min(b.min, b.max);
    simd_float3 bmax = simd_max(b.min, b.max);
    
    simd_float3 min = simd_min(amin, bmin);
    simd_float3 max = simd_max(amax, bmax);
    
    return (Bounds) { .min = min, .max = max };
}

Bounds transformBounds(Bounds a, simd_float4x4 transform) {
    simd_float3 min = simd_make_float3(simd_mul(transform, simd_make_float4(a.min, 1.0)));
    simd_float3 max = simd_make_float3(simd_mul(transform, simd_make_float4(a.max, 1.0)));
    return (Bounds) { .min = simd_min(min, max), .max = simd_max(min, max) };
}


