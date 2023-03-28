//
//  SuperShape.h
//  SuperShapes
//
//  Created by Reza Ali on 9/7/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

#ifndef SuperShapeGenerator_h
#define SuperShapeGenerator_h

#include "Types.h"

GeometryData generateSuperShapeGeometryData(float r1, float a1, float b1, float m1, float n11,
                                            float n21, float n31, float r2, float a2, float b2, float m2,
                                            float n12, float n22, float n32, int resTheta,
                                            int resPhi);

#endif /* SuperShapeGenerator_h */
