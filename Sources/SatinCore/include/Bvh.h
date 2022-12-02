//
//  Bvh.h
//  Satin
//
//  Created by Reza Ali on 11/27/22.
//

#ifndef Bvh_h
#define Bvh_h

#include "Types.h"

BVH createBVH(GeometryData geometry, bool useSAH);
void freeBVH(BVH bvh);

#endif /* Bvh_h */
