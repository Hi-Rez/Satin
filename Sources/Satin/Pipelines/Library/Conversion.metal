#include "Pi.metal"

#define k1Div180_f 1.0f / 180.0f
#define kRadians k1Div180_f *PI

float degToRad(float degrees) { return degrees * kRadians; }
