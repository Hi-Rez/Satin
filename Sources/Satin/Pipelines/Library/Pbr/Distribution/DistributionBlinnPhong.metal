float distributionBlinnPhong(float NoH, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;
    const float numerator = pow(NoH, (2.0 / alpha2) - 2.0);
    const float denominator = M_PI_F * alpha2;
    return numerator / max(denominator, 0.00001);
}
