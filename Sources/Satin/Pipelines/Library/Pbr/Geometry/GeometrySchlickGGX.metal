float geometrySchlickGGX(float NoX, float roughness)
{
    const float alpha = roughness * roughness;
    const float k = alpha / 2.0;
    const float numerator = NoX;
    float denominator = NoX * (1.0 - k) + k;
    return numerator / max(denominator, 0.00001);
}
