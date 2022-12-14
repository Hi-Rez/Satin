float distributionGGX(float NoH, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;
    const float NoH2 = NoH * NoH;

    float denominator = NoH2 * (alpha2 - 1.0) + 1.0;
    denominator = M_PI_F * denominator * denominator;
    return alpha2 / max(denominator, 0.00001);
}
