//
//  Math.c
//  Satin
//
//  Created by Reza Ali on 8/3/20.
//

#include "Math.h"

float map(float input, float inMin, float inMax, float outMin, float outMax) {
    return ((input - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}
