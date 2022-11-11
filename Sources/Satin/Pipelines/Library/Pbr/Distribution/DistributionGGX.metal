#include "../../Pi.metal"

float distributionGGX(float NoH, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;
    const float NoH2 = NoH * NoH;
    const float numerator = alpha2;
    float denominator = NoH2 * (alpha2 - 1.0) + 1.0;
    denominator = PI * denominator * denominator;
    return numerator / max(denominator, 0.00001);
}
