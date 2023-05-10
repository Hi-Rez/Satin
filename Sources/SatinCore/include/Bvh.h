//
//  Bvh.h
//  Satin
//
//  Created by Reza Ali on 11/27/22.
//

#ifndef Bvh_h
#define Bvh_h

#import "Types.h"

#if defined(__cplusplus)
extern "C" {
#endif

BVH createBVH(GeometryData geometry, bool useSAH);
void freeBVH(BVH bvh);

#if defined(__cplusplus)
}
#endif

#endif /* Bvh_h */
