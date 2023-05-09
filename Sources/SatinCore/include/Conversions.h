//
//  Math.h
//  Satin
//
//  Created by Reza Ali on 1/13/22.
//

#ifndef Helpers_h
#define Helpers_h

#if defined(__cplusplus)
extern "C" {
#endif

float degToRad(float degrees);
float radToDeg(float radians);

float remap(float input, float inMin, float inMax, float outMin, float outMax);

#if defined(__cplusplus)
}
#endif

#endif /* Helpers_h */
