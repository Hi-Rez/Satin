//
//  Vertex.h
//  Satin
//
//  Created by Reza Ali on 6/4/20.
//

#ifndef Vertex_h
#define Vertex_h

#include <simd/simd.h>

typedef struct {
    simd_float4 position;
    simd_float3 normal;
    simd_float2 uv;
} Vertex;

#endif /* Vertex_h */
