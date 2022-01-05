#include "Pi.metal"

float powAbs(float x, float power) { return (1.0 - pow(abs(x), power)); }

float powCos(float x, float power) { return pow(cos(PI * x * 0.5), power); }

float powAbsSin(float x, float power) { return 1.0 - pow(abs(sin(PI * x * 0.5)), power); }

float powMinCos(float x, float power) { return pow(min(cos(PI * x * 0.5), 1.0 - abs(x)), power); }

float powMaxAbs(float x, float power) { return 1.0 - pow(max(0.0, abs(x) * 2.0 - 1.0), power); }
