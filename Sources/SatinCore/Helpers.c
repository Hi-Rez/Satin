//
//  Helpers.c
//  Satin
//
//  Created by Reza Ali on 1/13/22.
//

#include "Helpers.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

float degToRad(float degrees) { return degrees * M_PI / 180.0; }

float radToDeg(float radians) { return radians * 180.0 / M_PI; }

//deprecated("Use remap() instead.")
float map(float input, float inMin, float inMax, float outMin, float outMax) {
    return ((input - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}
