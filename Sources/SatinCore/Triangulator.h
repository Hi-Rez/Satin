//
//  Triangulator.h
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

#ifndef Triangulator_h
#define Triangulator_h

#include "Types.h"

int extrudePaths(simd_float2 **paths, int *lengths, int count, GeometryData *gData);

int triangulate(simd_float2 **paths, int *lengths, int count, GeometryData *gData);

int triangulateMesh(Vertex *vertices, int vertexCount, const uint32_t **faces, int *faceLengths,
                    int faceCount, GeometryData *gData, TriangleFaceMap *triangleFaceMap);

#endif /* Triangulator_h */
