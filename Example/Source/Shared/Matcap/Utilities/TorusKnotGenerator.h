//
//  TorusKnotGenerator.h
//  Matcap-macOS
//
//  Created by Reza Ali on 6/2/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

#ifndef TorusKnotGenerator_h
#define TorusKnotGenerator_h

#include <simd/simd.h>

simd_float3 torusKnotGenerator(float t, float s, float R, float r, float c, float q, float p);

#endif /* TorusKnotGenerator_h */
