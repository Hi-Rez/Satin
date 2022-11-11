#include "../../Pi.metal"

float distributionBeckmann(float NoH, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;
    const float NoH2 = NoH * NoH;
    const float numerator = exp((NoH2)-1.0) / (alpha2 * NoH2);
    const float denominator = PI * alpha2 * NoH2 * NoH2;
    return numerator / max(denominator, 0.00001);
}
