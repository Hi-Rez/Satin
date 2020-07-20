//
//  Triangulator.h
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

#ifndef Triangulator_h
#define Triangulator_h

#include "Types.h"

int triangulate(simd_float2 **paths, int *lengths, int count, GeometryData *gData);
int extrudePaths(simd_float2 **paths, int *lengths, int count, GeometryData *gData);

#endif /* Triangulator_h */
